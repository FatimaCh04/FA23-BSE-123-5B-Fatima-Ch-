import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sync_service.dart';
import 'product_provider.dart';
import 'customer_provider.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  double unitPrice;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get totalPrice => (unitPrice - discount) * quantity;
  double get profit => (unitPrice - discount - product.costPrice) * quantity;

  CartItem copyWith({
    ProductModel? product,
    int? quantity,
    double? unitPrice,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
    );
  }
}

class POSProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<CartItem> _cart = [];
  CustomerModel? _selectedCustomer;
  double _discountPercent = 0.0;
  double _discountAmount = 0.0;
  double _taxPercent = 0.0;
  String _paymentMethod = AppConstants.paymentCash;
  double _paidAmount = 0.0;
  String _notes = '';
  bool _isProcessing = false;
  String? _errorMessage;

  // Recent sales
  List<SaleModel> _recentSales = [];
  List<SaleModel> _todaySales = [];
  List<SaleModel> _allSales = [];

  List<CartItem> get cart => _cart;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  double get discountPercent => _discountPercent;
  double get discountAmount => _discountAmount;
  double get taxPercent => _taxPercent;
  String get paymentMethod => _paymentMethod;
  double get paidAmount => _paidAmount;
  String get notes => _notes;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  List<SaleModel> get recentSales => _recentSales;
  List<SaleModel> get todaySales => _todaySales;
  List<SaleModel> get allSales => _allSales;

  // Calculated values
  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get calculatedDiscount {
    if (_discountAmount > 0) {
      return _discountAmount;
    }
    return subtotal * (_discountPercent / 100);
  }

  double get afterDiscount => subtotal - calculatedDiscount;
  double get taxAmount => afterDiscount * (_taxPercent / 100);
  double get totalAmount => afterDiscount + taxAmount;
  double get dueAmount => totalAmount - _paidAmount;
  int get totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get totalProfit => _cart.fold(0.0, (sum, item) => sum + item.profit);

  bool get isCartEmpty => _cart.isEmpty;
  bool get canCheckout => !isCartEmpty && (_paidAmount > 0 || _selectedCustomer != null);

  // Cart Operations
  void addToCart(ProductModel product) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      // Check stock
      if (_cart[existingIndex].quantity >= product.quantity) {
        _errorMessage = 'Insufficient stock';
        notifyListeners();
        return;
      }
      _cart[existingIndex].quantity++;
    } else {
      if (product.quantity <= 0) {
        _errorMessage = 'Product out of stock';
        notifyListeners();
        return;
      }
      _cart.add(CartItem(
        product: product,
        quantity: 1,
        unitPrice: product.salePrice,
      ));
    }
    
    _errorMessage = null;
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else if (quantity <= _cart[index].product.quantity) {
        _cart[index].quantity = quantity;
      } else {
        _errorMessage = 'Insufficient stock';
        notifyListeners();
        return;
      }
    }
    _errorMessage = null;
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_cart[index].quantity < _cart[index].product.quantity) {
        _cart[index].quantity++;
        _errorMessage = null;
      } else {
        _errorMessage = 'Insufficient stock';
      }
    }
    notifyListeners();
  }

  void decrementQuantity(String productId) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    }
    notifyListeners();
  }

  void updateItemPrice(String productId, double price) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _cart[index].unitPrice = price;
    }
    notifyListeners();
  }

  void updateItemDiscount(String productId, double discount) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _cart[index].discount = discount;
    }
    notifyListeners();
  }

  void setCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscountPercent(double percent) {
    _discountPercent = percent;
    _discountAmount = 0.0;
    notifyListeners();
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount;
    _discountPercent = 0.0;
    notifyListeners();
  }

  void setTaxPercent(double percent) {
    _taxPercent = percent;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  void clearCart() {
    _cart = [];
    _selectedCustomer = null;
    _discountPercent = 0.0;
    _discountAmount = 0.0;
    _paidAmount = 0.0;
    _notes = '';
    _errorMessage = null;
    notifyListeners();
  }

  // Process Sale
  Future<SaleModel?> processSale({
    required ProductProvider productProvider,
    required CustomerProvider customerProvider,
  }) async {
    debugPrint('[POSProvider] processSale called');
    debugPrint('[POSProvider] Cart items: ${_cart.length}');
    
    if (_cart.isEmpty) {
      _errorMessage = 'Cart is empty';
      debugPrint('[POSProvider] Error: Cart is empty');
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      debugPrint('[POSProvider] User ID: $userId');
      final saleId = _uuid.v4();
      final invoiceNumber = await _generateInvoiceNumber();

      // Create sale items
      final saleItems = _cart.map((item) => SaleItemModel(
        id: _uuid.v4(),
        saleId: saleId,
        productId: item.product.id,
        productName: item.product.name,
        sku: item.product.sku,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        costPrice: item.product.costPrice,
        discountAmount: item.discount,
        totalPrice: item.totalPrice,
      )).toList();

      // Calculate due
      final due = dueAmount > 0 ? dueAmount : 0.0;

      // Create sale
      final sale = SaleModel(
        id: saleId,
        invoiceNumber: invoiceNumber,
        customerId: _selectedCustomer?.id ?? 'walk_in',
        customerName: _selectedCustomer?.name ?? 'Walk-in Customer',
        items: saleItems,
        subtotal: subtotal,
        discountAmount: calculatedDiscount,
        discountPercent: _discountPercent,
        taxAmount: taxAmount,
        taxPercent: _taxPercent,
        totalAmount: totalAmount,
        paidAmount: _paidAmount,
        dueAmount: due,
        paymentMethod: _paymentMethod,
        notes: _notes,
        saleDate: DateTime.now(),
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      // Save sale to database - remove 'items' as it's stored separately
      final saleJson = sale.toJson();
      saleJson.remove('items'); // Don't store items in sale table
      debugPrint('[POSProvider] Saving sale: $saleJson');
      await _db.insert(AppConstants.salesTable, saleJson);

      // Save sale items
      for (final item in saleItems) {
        await _db.insert(AppConstants.saleItemsTable, item.toJson());
      }

      // Update product quantities
      debugPrint('[POSProvider] Updating stock for ${_cart.length} items');
      for (final item in _cart) {
        debugPrint('[POSProvider] Updating stock for product: ${item.product.id} (${item.product.name}), qty: ${item.quantity}');
        final stockUpdated = await productProvider.updateStock(
          productId: item.product.id,
          quantity: item.quantity,
          operationType: AppConstants.stockSale,
          notes: 'Sale #$invoiceNumber',
        );
        debugPrint('[POSProvider] Stock update result: $stockUpdated');
      }

      // Record sale for customer history (all sales to registered customers)
      if (_selectedCustomer != null && _selectedCustomer!.id != 'walk_in') {
        // Record the sale in customer's statement
        await customerProvider.recordSale(
          customerId: _selectedCustomer!.id,
          totalAmount: totalAmount,
          paidAmount: _paidAmount,
          invoiceNumber: invoiceNumber,
          saleId: saleId,
        );
        
        // Handle credit if there's due amount
        if (due > 0) {
          await customerProvider.addCredit(
            customerId: _selectedCustomer!.id,
            amount: due,
            description: 'Credit sale #$invoiceNumber',
            referenceId: saleId,
            referenceType: 'sale',
          );
        }
      }

      // Clear cart and reload sales
      clearCart();
      await loadRecentSales();
      await loadTodaySales();

      _syncService.syncTable(AppConstants.salesTable);

      _isProcessing = false;
      notifyListeners();

      return sale;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to process sale: $e';
      debugPrint('[POSProvider] Error processing sale: $e');
      debugPrint('[POSProvider] Stack trace: $stackTrace');
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    // Get count of today's sales
    final todayStart = DateTime(now.year, now.month, now.day);
    final results = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.salesTable} WHERE sale_date >= ?',
      [todayStart.toIso8601String()],
    );
    
    final count = (results.first['count'] as int) + 1;
    return 'INV-$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  // Load sales
  Future<void> loadRecentSales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.salesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'sale_date DESC',
        limit: 20,
      );

      _recentSales = await Future.wait(results.map((sale) async {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        return SaleModel.fromJson({
          ...sale,
          'items': items,
        });
      }));

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recent sales: $e');
    }
  }

  Future<void> loadTodaySales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final results = await _db.query(
        AppConstants.salesTable,
        where: 'user_id = ? AND sale_date >= ?',
        whereArgs: [userId, todayStart.toIso8601String()],
        orderBy: 'sale_date DESC',
      );

      _todaySales = await Future.wait(results.map((sale) async {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        return SaleModel.fromJson({
          ...sale,
          'items': items,
        });
      }));

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load today\'s sales: $e');
    }
  }

  // Load all sales for export
  Future<void> loadAllSales() async {
    try {
      debugPrint('[POSProvider] Loading all sales for export...');
      
      // Load all sales (no user filter for export to include all data)
      final results = await _db.query(
        AppConstants.salesTable,
        where: 'is_void = 0',
        orderBy: 'sale_date DESC',
      );

      debugPrint('[POSProvider] Found ${results.length} sales in database');

      _allSales = await Future.wait(results.map((sale) async {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        debugPrint('[POSProvider] Sale ${sale['invoice_number']}: ${items.length} items');
        return SaleModel.fromJson({
          ...sale,
          'items': items,
        });
      }));

      debugPrint('[POSProvider] Loaded ${_allSales.length} sales for export');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Failed to load all sales: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<SaleModel?> getSaleById(String saleId) async {
    try {
      final results = await _db.query(
        AppConstants.salesTable,
        where: 'id = ?',
        whereArgs: [saleId],
      );

      if (results.isEmpty) return null;

      final items = await _db.query(
        AppConstants.saleItemsTable,
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      return SaleModel.fromJson({
        ...results.first,
        'items': items,
      });
    } catch (e) {
      debugPrint('Failed to get sale: $e');
      return null;
    }
  }

  // Statistics
  double get todayTotal => _todaySales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  int get todaySalesCount => _todaySales.length;
  double get todayProfit => _todaySales.fold(0.0, (sum, sale) => sum + sale.totalProfit);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

