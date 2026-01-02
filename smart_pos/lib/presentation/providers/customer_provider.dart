import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/ledger_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sync_service.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<CustomerModel> _customers = [];
  List<LedgerModel> _ledgerEntries = [];
  List<SaleModel> _customerPurchaseHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _customerTypeFilter = 'all'; // all, regular, walk_in
  String _ledgerDateFilter = 'all'; // all, today, week, month, custom
  DateTime? _ledgerStartDate;
  DateTime? _ledgerEndDate;
  String? _selectedCustomerIdForLedger;

  List<CustomerModel> get customers => _filteredCustomers;
  List<CustomerModel> get filteredCustomers => _filteredCustomers;
  List<CustomerModel> get allCustomers => _customers;
  List<CustomerModel> get regularCustomers => 
      _customers.where((c) => c.customerType == AppConstants.customerRegular && c.isActive).toList();
  List<CustomerModel> get customersWithOutstanding => 
      _customers.where((c) => c.hasOutstanding && c.isActive).toList();
  List<LedgerModel> get ledgerEntries => _filteredLedgerEntries;
  List<LedgerModel> get allLedgerEntries => _ledgerEntries;
  List<SaleModel> get customerPurchaseHistory => _customerPurchaseHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get customerTypeFilter => _customerTypeFilter;
  String get ledgerDateFilter => _ledgerDateFilter;
  DateTime? get ledgerStartDate => _ledgerStartDate;
  DateTime? get ledgerEndDate => _ledgerEndDate;
  String? get selectedCustomerIdForLedger => _selectedCustomerIdForLedger;

  List<CustomerModel> get _filteredCustomers {
    var filtered = _customers.where((c) => c.isActive).toList();

    // Apply customer type filter
    if (_customerTypeFilter == 'regular') {
      filtered = filtered.where((c) => c.customerType == AppConstants.customerRegular).toList();
    } else if (_customerTypeFilter == 'walk_in') {
      filtered = filtered.where((c) => c.customerType == AppConstants.customerWalkIn).toList();
    } else if (_customerTypeFilter == 'with_balance') {
      filtered = filtered.where((c) => c.hasOutstanding).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) =>
          c.name.toLowerCase().contains(query) ||
          (c.phone?.toLowerCase().contains(query) ?? false) ||
          (c.email?.toLowerCase().contains(query) ?? false)).toList();
    }

    return filtered;
  }

  List<LedgerModel> get _filteredLedgerEntries {
    var filtered = _ledgerEntries.toList();

    // Apply customer filter
    if (_selectedCustomerIdForLedger != null && _selectedCustomerIdForLedger!.isNotEmpty) {
      filtered = filtered.where((l) => l.customerId == _selectedCustomerIdForLedger).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    switch (_ledgerDateFilter) {
      case 'today':
        final todayStart = DateTime(now.year, now.month, now.day);
        filtered = filtered.where((l) => l.transactionDate.isAfter(todayStart)).toList();
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        filtered = filtered.where((l) => l.transactionDate.isAfter(weekStartDate)).toList();
        break;
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        filtered = filtered.where((l) => l.transactionDate.isAfter(monthStart)).toList();
        break;
      case 'custom':
        if (_ledgerStartDate != null) {
          filtered = filtered.where((l) => l.transactionDate.isAfter(_ledgerStartDate!)).toList();
        }
        if (_ledgerEndDate != null) {
          final endDate = DateTime(_ledgerEndDate!.year, _ledgerEndDate!.month, _ledgerEndDate!.day, 23, 59, 59);
          filtered = filtered.where((l) => l.transactionDate.isBefore(endDate)).toList();
        }
        break;
    }

    return filtered;
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      // Query customers - handle case where user_id might be null
      List<Map<String, dynamic>> results;
      if (userId != null && userId.isNotEmpty) {
        results = await _db.query(
          AppConstants.customersTable,
          where: '(user_id = ? OR user_id IS NULL) AND is_active = 1',
          whereArgs: [userId],
          orderBy: 'name ASC',
        );
      } else {
        results = await _db.query(
          AppConstants.customersTable,
          where: 'is_active = 1',
          orderBy: 'name ASC',
        );
      }

      _customers = results.map((e) => CustomerModel.fromJson(e)).toList();
      
      // Update user_id for customers that don't have one
      if (userId != null && userId.isNotEmpty) {
        for (var customer in _customers) {
          if (customer.userId == null || customer.userId!.isEmpty) {
            await _db.update(
              AppConstants.customersTable,
              {'user_id': userId},
              where: 'id = ?',
              whereArgs: [customer.id],
            );
          }
        }
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load customers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final newCustomer = CustomerModel(
        id: _uuid.v4(),
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        customerType: customer.customerType,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.customersTable, newCustomer.toJson());
      _customers.add(newCustomer);
      notifyListeners();

      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    try {
      final updated = customer.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.customersTable,
        updated.toJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = updated;
      }
      notifyListeners();

      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      // Check if customer has outstanding balance
      final customer = _customers.firstWhere((c) => c.id == customerId);
      if (customer.hasOutstanding) {
        _errorMessage = 'Cannot delete customer with outstanding balance';
        notifyListeners();
        return false;
      }

      await _db.update(
        AppConstants.customersTable,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': AppConstants.syncPending,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );

      _customers.removeWhere((c) => c.id == customerId);
      notifyListeners();

      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final balanceBefore = customer.outstandingBalance;
      final balanceAfter = balanceBefore - amount;

      // Create ledger entry
      final ledgerEntry = LedgerModel(
        id: _uuid.v4(),
        customerId: customerId,
        customerName: customer.name,
        transactionType: AppConstants.transactionPayment,
        description: notes ?? 'Payment received',
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter > 0 ? balanceAfter : 0,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.ledgerTable, ledgerEntry.toJson());

      // Update customer balance
      final updatedCustomer = customer.copyWith(
        totalPayments: customer.totalPayments + amount,
        outstandingBalance: balanceAfter > 0 ? balanceAfter : 0,
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.customersTable,
        updatedCustomer.toJson(),
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
      notifyListeners();

      _syncService.syncTable(AppConstants.ledgerTable);
      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCredit({
    required String customerId,
    required double amount,
    required String description,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final balanceBefore = customer.outstandingBalance;
      final balanceAfter = balanceBefore + amount;

      // Create ledger entry
      final ledgerEntry = LedgerModel(
        id: _uuid.v4(),
        customerId: customerId,
        customerName: customer.name,
        transactionType: AppConstants.transactionCredit,
        referenceId: referenceId,
        referenceType: referenceType,
        description: description,
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.ledgerTable, ledgerEntry.toJson());

      // Update customer balance
      final updatedCustomer = customer.copyWith(
        totalPurchases: customer.totalPurchases + amount,
        outstandingBalance: balanceAfter,
        lastPurchaseDate: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.customersTable,
        updatedCustomer.toJson(),
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
      notifyListeners();

      _syncService.syncTable(AppConstants.ledgerTable);
      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add credit: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<LedgerModel>> getCustomerLedger(String customerId) async {
    final results = await _db.query(
      AppConstants.ledgerTable,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'transaction_date DESC',
    );

    return results.map((e) => LedgerModel.fromJson(e)).toList();
  }

  Future<void> loadAllLedgerEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.ledgerTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'transaction_date DESC',
      );

      _ledgerEntries = results.map((e) => LedgerModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load ledger entries: $e';
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  CustomerModel? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  int get totalCustomers => _customers.where((c) => c.isActive).length;
  int get regularCustomerCount => regularCustomers.length;
  int get customersWithOutstandingCount => customersWithOutstanding.length;
  double get totalOutstanding => _customers.fold(0.0, (sum, c) => sum + c.outstandingBalance);
  double get totalReceivables => totalOutstanding;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Filter Methods
  void setCustomerTypeFilter(String filter) {
    _customerTypeFilter = filter;
    notifyListeners();
  }

  void setLedgerDateFilter(String filter) {
    _ledgerDateFilter = filter;
    if (filter != 'custom') {
      _ledgerStartDate = null;
      _ledgerEndDate = null;
    }
    notifyListeners();
  }

  void setLedgerCustomDateRange(DateTime? start, DateTime? end) {
    _ledgerDateFilter = 'custom';
    _ledgerStartDate = start;
    _ledgerEndDate = end;
    notifyListeners();
  }

  void setLedgerCustomerFilter(String? customerId) {
    _selectedCustomerIdForLedger = customerId;
    notifyListeners();
  }

  void clearLedgerFilters() {
    _ledgerDateFilter = 'all';
    _ledgerStartDate = null;
    _ledgerEndDate = null;
    _selectedCustomerIdForLedger = null;
    notifyListeners();
  }

  // Customer Purchase History
  Future<List<SaleModel>> getCustomerPurchaseHistory(String customerId) async {
    try {
      final results = await _db.query(
        AppConstants.salesTable,
        where: 'customer_id = ? AND is_void = 0',
        whereArgs: [customerId],
        orderBy: 'sale_date DESC',
      );

      List<SaleModel> sales = [];
      for (var saleData in results) {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [saleData['id']],
        );
        sales.add(SaleModel.fromJson({
          ...saleData,
          'items': items,
        }));
      }

      _customerPurchaseHistory = sales;
      notifyListeners();
      return sales;
    } catch (e) {
      debugPrint('Failed to load customer purchase history: $e');
      return [];
    }
  }

  // Record Sale to Customer (for statement history)
  Future<bool> recordSale({
    required String customerId,
    required double totalAmount,
    required double paidAmount,
    required String invoiceNumber,
    required String saleId,
  }) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      // Create a ledger entry for the sale
      final ledgerEntry = LedgerModel(
        id: _uuid.v4(),
        customerId: customerId,
        customerName: customer.name,
        transactionType: 'sale',
        referenceId: saleId,
        referenceType: 'sale',
        description: 'Sale #$invoiceNumber - Total: PKR ${totalAmount.toStringAsFixed(0)}, Paid: PKR ${paidAmount.toStringAsFixed(0)}',
        amount: totalAmount,
        balanceBefore: customer.outstandingBalance,
        balanceAfter: customer.outstandingBalance, // Balance doesn't change for recording sale
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.ledgerTable, ledgerEntry.toJson());
      
      _syncService.syncTable(AppConstants.ledgerTable);
      
      return true;
    } catch (e) {
      debugPrint('Failed to record sale: $e');
      return false;
    }
  }

  // Add Debit Entry (for opening balance, adjustments, etc.)
  Future<bool> addDebit({
    required String customerId,
    required double amount,
    required String description,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final balanceBefore = customer.outstandingBalance;
      final balanceAfter = balanceBefore + amount;

      // Create ledger entry
      final ledgerEntry = LedgerModel(
        id: _uuid.v4(),
        customerId: customerId,
        customerName: customer.name,
        transactionType: AppConstants.transactionDebit,
        referenceId: referenceId,
        referenceType: referenceType ?? 'adjustment',
        description: description,
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.ledgerTable, ledgerEntry.toJson());

      // Update customer balance
      final updatedCustomer = customer.copyWith(
        outstandingBalance: balanceAfter,
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.customersTable,
        updatedCustomer.toJson(),
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
      notifyListeners();

      _syncService.syncTable(AppConstants.ledgerTable);
      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add debit: $e';
      notifyListeners();
      return false;
    }
  }

  // Get Customer Statement (all ledger entries with running balance)
  Future<List<Map<String, dynamic>>> getCustomerStatement(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = 'customer_id = ?';
      List<dynamic> whereArgs = [customerId];

      if (startDate != null) {
        whereClause += ' AND transaction_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClause += ' AND transaction_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final results = await _db.query(
        AppConstants.ledgerTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'transaction_date ASC',
      );

      List<Map<String, dynamic>> statement = [];
      double runningBalance = 0.0;

      for (var entry in results) {
        final ledger = LedgerModel.fromJson(entry);
        runningBalance = ledger.balanceAfter;
        statement.add({
          'ledger': ledger,
          'running_balance': runningBalance,
        });
      }

      return statement;
    } catch (e) {
      debugPrint('Failed to get customer statement: $e');
      return [];
    }
  }

  // Get Ledger Summary for a customer
  Future<Map<String, double>> getCustomerLedgerSummary(String customerId) async {
    try {
      final results = await _db.query(
        AppConstants.ledgerTable,
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );

      double totalDebits = 0.0;
      double totalCredits = 0.0;
      double totalPayments = 0.0;

      for (var entry in results) {
        final ledger = LedgerModel.fromJson(entry);
        if (ledger.isDebit) {
          totalDebits += ledger.amount;
        } else if (ledger.isCredit) {
          totalCredits += ledger.amount;
        } else if (ledger.isPayment) {
          totalPayments += ledger.amount;
        }
      }

      return {
        'total_debits': totalDebits,
        'total_credits': totalCredits,
        'total_payments': totalPayments,
        'net_balance': totalCredits - totalPayments,
      };
    } catch (e) {
      debugPrint('Failed to get customer ledger summary: $e');
      return {
        'total_debits': 0.0,
        'total_credits': 0.0,
        'total_payments': 0.0,
        'net_balance': 0.0,
      };
    }
  }

  // Get All Time Statistics
  Map<String, dynamic> get customerStatistics {
    final activeCustomers = _customers.where((c) => c.isActive).toList();
    final regular = activeCustomers.where((c) => c.customerType == AppConstants.customerRegular).length;
    final withBalance = activeCustomers.where((c) => c.hasOutstanding).length;
    final totalPurchases = activeCustomers.fold(0.0, (sum, c) => sum + c.totalPurchases);
    final totalPayments = activeCustomers.fold(0.0, (sum, c) => sum + c.totalPayments);
    final totalOutstanding = activeCustomers.fold(0.0, (sum, c) => sum + c.outstandingBalance);

    return {
      'total_customers': activeCustomers.length,
      'regular_customers': regular,
      'customers_with_balance': withBalance,
      'total_purchases': totalPurchases,
      'total_payments': totalPayments,
      'total_outstanding': totalOutstanding,
    };
  }

  // Ledger Statistics
  Map<String, dynamic> get ledgerStatistics {
    final filtered = _filteredLedgerEntries;
    final debits = filtered.where((l) => l.isDebit || l.isCredit);
    final payments = filtered.where((l) => l.isPayment);

    return {
      'total_transactions': filtered.length,
      'total_debits_credits': debits.fold(0.0, (sum, l) => sum + l.amount),
      'total_payments': payments.fold(0.0, (sum, l) => sum + l.amount),
      'debit_count': debits.length,
      'payment_count': payments.length,
    };
  }

  // Void/Cancel a ledger entry (with reverse entry)
  Future<bool> reverseLedgerEntry(String ledgerId, String reason) async {
    try {
      // Find the original entry
      final results = await _db.query(
        AppConstants.ledgerTable,
        where: 'id = ?',
        whereArgs: [ledgerId],
      );

      if (results.isEmpty) {
        _errorMessage = 'Ledger entry not found';
        notifyListeners();
        return false;
      }

      final originalEntry = LedgerModel.fromJson(results.first);
      final customer = _customers.firstWhere((c) => c.id == originalEntry.customerId);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      // Calculate reverse balance
      final balanceBefore = customer.outstandingBalance;
      double balanceAfter;
      String reverseType;

      if (originalEntry.isPayment) {
        // Reverse payment means add back to balance
        balanceAfter = balanceBefore + originalEntry.amount;
        reverseType = AppConstants.transactionCredit;
      } else {
        // Reverse credit/debit means subtract from balance
        balanceAfter = balanceBefore - originalEntry.amount;
        reverseType = AppConstants.transactionPayment;
      }

      // Create reverse entry
      final reverseEntry = LedgerModel(
        id: _uuid.v4(),
        customerId: originalEntry.customerId,
        customerName: originalEntry.customerName,
        transactionType: reverseType,
        referenceId: ledgerId,
        referenceType: 'reversal',
        description: 'Reversal: ${originalEntry.description} - $reason',
        amount: originalEntry.amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter > 0 ? balanceAfter : 0,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.ledgerTable, reverseEntry.toJson());

      // Update customer balance
      final updatedCustomer = customer.copyWith(
        outstandingBalance: balanceAfter > 0 ? balanceAfter : 0,
        totalPayments: originalEntry.isPayment 
            ? customer.totalPayments - originalEntry.amount 
            : customer.totalPayments,
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.customersTable,
        updatedCustomer.toJson(),
        where: 'id = ?',
        whereArgs: [originalEntry.customerId],
      );

      final index = _customers.indexWhere((c) => c.id == originalEntry.customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }

      await loadAllLedgerEntries();

      _syncService.syncTable(AppConstants.ledgerTable);
      _syncService.syncTable(AppConstants.customersTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to reverse entry: $e';
      notifyListeners();
      return false;
    }
  }

  // Get top customers by purchase amount
  List<CustomerModel> getTopCustomers({int limit = 10}) {
    final sorted = List<CustomerModel>.from(_customers.where((c) => c.isActive));
    sorted.sort((a, b) => b.totalPurchases.compareTo(a.totalPurchases));
    return sorted.take(limit).toList();
  }

  // Get customers with overdue payments (customize based on credit terms)
  List<CustomerModel> getOverdueCustomers({int daysOverdue = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOverdue));
    return _customers.where((c) => 
      c.isActive && 
      c.hasOutstanding && 
      c.lastPurchaseDate != null && 
      c.lastPurchaseDate!.isBefore(cutoffDate)
    ).toList();
  }
}

