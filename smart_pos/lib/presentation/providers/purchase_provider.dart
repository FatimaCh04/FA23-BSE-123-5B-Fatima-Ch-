import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sync_service.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/purchase_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_history_model.dart';
import '../../data/models/vendor_model.dart';

class PurchaseProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  final _syncService = SyncService();
  final _uuid = const Uuid();

  List<PurchaseModel> _purchases = [];
  List<PurchaseModel> get purchases => _purchases;

  List<PurchaseItemModel> _currentItems = [];
  List<PurchaseItemModel> get currentItems => _currentItems;

  VendorModel? _selectedVendor;
  VendorModel? get selectedVendor => _selectedVendor;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Statistics
  double _totalPurchases = 0;
  double get totalPurchases => _totalPurchases;

  double _totalUnpaid = 0;
  double get totalUnpaid => _totalUnpaid;

  int _purchaseCount = 0;
  int get purchaseCount => _purchaseCount;

  // Load all purchases
  Future<void> loadPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.purchasesTable,
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'purchase_date DESC',
      );

      _purchases = results.map((e) => PurchaseModel.fromJson(e)).toList();

      // Load items for each purchase
      for (var i = 0; i < _purchases.length; i++) {
        final items = await _loadPurchaseItems(_purchases[i].id);
        _purchases[i] = _purchases[i].copyWith(items: items);
      }

      // Calculate statistics
      _calculateStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load purchases: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<PurchaseItemModel>> _loadPurchaseItems(String purchaseId) async {
    final results = await _db.query(
      AppConstants.purchaseItemsTable,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return results.map((e) => PurchaseItemModel.fromJson(e)).toList();
  }

  void _calculateStats() {
    _totalPurchases = 0;
    _totalUnpaid = 0;
    _purchaseCount = _purchases.length;

    for (var purchase in _purchases) {
      _totalPurchases += purchase.totalAmount;
      _totalUnpaid += purchase.dueAmount;
    }
  }

  // Set selected vendor
  void setSelectedVendor(VendorModel? vendor) {
    _selectedVendor = vendor;
    notifyListeners();
  }

  // Add item to current purchase
  void addItem(ProductModel product, int quantity) {
    final existingIndex = _currentItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      // Update quantity
      final existing = _currentItems[existingIndex];
      _currentItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
        totalPrice: (existing.quantity + quantity) * existing.costPrice,
      );
    } else {
      // Add new item
      _currentItems.add(PurchaseItemModel(
        id: _uuid.v4(),
        purchaseId: '',
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        quantity: quantity,
        costPrice: product.costPrice,
        totalPrice: quantity * product.costPrice,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      ));
    }
    notifyListeners();
  }

  // Update item quantity
  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _currentItems.length) {
      if (quantity <= 0) {
        _currentItems.removeAt(index);
      } else {
        final item = _currentItems[index];
        _currentItems[index] = item.copyWith(
          quantity: quantity,
          totalPrice: quantity * item.costPrice,
        );
      }
      notifyListeners();
    }
  }

  // Remove item
  void removeItem(int index) {
    if (index >= 0 && index < _currentItems.length) {
      _currentItems.removeAt(index);
      notifyListeners();
    }
  }

  // Clear current items
  void clearItems() {
    _currentItems.clear();
    _selectedVendor = null;
    notifyListeners();
  }

  // Get subtotal
  double get subtotal {
    return _currentItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Create purchase
  Future<bool> createPurchase({
    required String invoiceNumber,
    double taxAmount = 0,
    double discountAmount = 0,
    double paidAmount = 0,
    String? notes,
  }) async {
    if (_selectedVendor == null) {
      _errorMessage = 'Please select a vendor';
      notifyListeners();
      return false;
    }

    if (_currentItems.isEmpty) {
      _errorMessage = 'Please add at least one item';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final purchaseId = _uuid.v4();
      final totalAmount = subtotal + taxAmount - discountAmount;
      final dueAmount = totalAmount - paidAmount;
      
      String paymentStatus = 'unpaid';
      if (paidAmount >= totalAmount) {
        paymentStatus = 'paid';
      } else if (paidAmount > 0) {
        paymentStatus = 'partial';
      }

      // Create purchase
      final purchase = PurchaseModel(
        id: purchaseId,
        vendorId: _selectedVendor!.id,
        vendorName: _selectedVendor!.name,
        invoiceNumber: invoiceNumber,
        purchaseDate: DateTime.now(),
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        dueAmount: dueAmount,
        paymentStatus: paymentStatus,
        notes: notes,
        isActive: true,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.purchasesTable, purchase.toJson());

      // Save purchase items and update stock
      for (var item in _currentItems) {
        final purchaseItem = item.copyWith(purchaseId: purchaseId);
        await _db.insert(AppConstants.purchaseItemsTable, purchaseItem.toJson());

        // Update product stock
        await _updateProductStock(
          purchaseId: purchaseId,
          productId: item.productId,
          productName: item.productName ?? '',
          quantity: item.quantity,
          vendorId: _selectedVendor!.id,
          vendorName: _selectedVendor!.name,
          userId: userId,
        );
      }

      // Update vendor totals
      await _updateVendorTotals(_selectedVendor!.id, totalAmount, dueAmount);

      // Sync
      _syncService.syncTable(AppConstants.purchasesTable);

      // Clear and reload
      clearItems();
      await loadPurchases();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create purchase: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateProductStock({
    required String purchaseId,
    required String productId,
    required String productName,
    required int quantity,
    required String vendorId,
    required String vendorName,
    String? userId,
  }) async {
    // Get current product
    final productResults = await _db.query(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productResults.isEmpty) return;

    final product = ProductModel.fromJson(productResults.first);
    final newQuantity = product.quantity + quantity;

    // Update product quantity
    await _db.update(
      AppConstants.productsTable,
      {
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': AppConstants.syncPending,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );

    // Create stock history record with vendor info
    final stockHistory = StockHistoryModel(
      id: _uuid.v4(),
      productId: productId,
      productName: productName,
      operationType: 'purchase',
      quantityBefore: product.quantity,
      quantityChange: quantity,
      quantityAfter: newQuantity,
      referenceId: purchaseId,
      referenceType: 'purchase',
      vendorId: vendorId,
      vendorName: vendorName,
      purchaseId: purchaseId,
      notes: 'Stock added via purchase',
      operationDate: DateTime.now(),
      createdAt: DateTime.now(),
      syncStatus: AppConstants.syncPending,
      userId: userId,
    );

    await _db.insert(AppConstants.stockHistoryTable, stockHistory.toJson());
  }

  Future<void> _updateVendorTotals(String vendorId, double totalAmount, double dueAmount) async {
    final vendorResults = await _db.query(
      AppConstants.vendorsTable,
      where: 'id = ?',
      whereArgs: [vendorId],
    );

    if (vendorResults.isEmpty) return;

    final vendor = VendorModel.fromJson(vendorResults.first);

    await _db.update(
      AppConstants.vendorsTable,
      {
        'total_purchases': vendor.totalPurchases + totalAmount,
        'outstanding_balance': vendor.outstandingBalance + dueAmount,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': AppConstants.syncPending,
      },
      where: 'id = ?',
      whereArgs: [vendorId],
    );
  }

  // Record payment for purchase
  Future<bool> recordPayment(String purchaseId, double amount) async {
    try {
      final purchaseResults = await _db.query(
        AppConstants.purchasesTable,
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      if (purchaseResults.isEmpty) {
        _errorMessage = 'Purchase not found';
        notifyListeners();
        return false;
      }

      final purchase = PurchaseModel.fromJson(purchaseResults.first);
      final newPaidAmount = purchase.paidAmount + amount;
      final newDueAmount = purchase.totalAmount - newPaidAmount;

      String paymentStatus = 'unpaid';
      if (newPaidAmount >= purchase.totalAmount) {
        paymentStatus = 'paid';
      } else if (newPaidAmount > 0) {
        paymentStatus = 'partial';
      }

      await _db.update(
        AppConstants.purchasesTable,
        {
          'paid_amount': newPaidAmount,
          'due_amount': newDueAmount > 0 ? newDueAmount : 0,
          'payment_status': paymentStatus,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': AppConstants.syncPending,
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      // Update vendor outstanding balance
      await _db.rawQuery('''
        UPDATE ${AppConstants.vendorsTable}
        SET outstanding_balance = outstanding_balance - ?,
            updated_at = ?,
            sync_status = ?
        WHERE id = ?
      ''', [amount, DateTime.now().toIso8601String(), AppConstants.syncPending, purchase.vendorId]);

      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete purchase
  Future<bool> deletePurchase(String purchaseId) async {
    try {
      await _db.update(
        AppConstants.purchasesTable,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': AppConstants.syncPending,
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete purchase: $e';
      notifyListeners();
      return false;
    }
  }

  // Get purchases by vendor
  List<PurchaseModel> getPurchasesByVendor(String vendorId) {
    return _purchases.where((p) => p.vendorId == vendorId).toList();
  }

  // Get unpaid purchases
  List<PurchaseModel> get unpaidPurchases {
    return _purchases.where((p) => p.paymentStatus != 'paid').toList();
  }

  // Generate invoice number
  Future<String> generateInvoiceNumber() async {
    final count = _purchases.length + 1;
    final date = DateTime.now();
    return 'PO-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${count.toString().padLeft(4, '0')}';
  }
}

