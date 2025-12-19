import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/ledger_model.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sync_service.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<CustomerModel> _customers = [];
  List<LedgerModel> _ledgerEntries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<CustomerModel> get customers => _filteredCustomers;
  List<CustomerModel> get allCustomers => _customers;
  List<CustomerModel> get regularCustomers => 
      _customers.where((c) => c.customerType == AppConstants.customerRegular && c.isActive).toList();
  List<CustomerModel> get customersWithOutstanding => 
      _customers.where((c) => c.hasOutstanding && c.isActive).toList();
  List<LedgerModel> get ledgerEntries => _ledgerEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<CustomerModel> get _filteredCustomers {
    var filtered = _customers.where((c) => c.isActive).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) =>
          c.name.toLowerCase().contains(query) ||
          (c.phone?.toLowerCase().contains(query) ?? false) ||
          (c.email?.toLowerCase().contains(query) ?? false)).toList();
    }

    return filtered;
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.customersTable,
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );

      _customers = results.map((e) => CustomerModel.fromJson(e)).toList();
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
}

