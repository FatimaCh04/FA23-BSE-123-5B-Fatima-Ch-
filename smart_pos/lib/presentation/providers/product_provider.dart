import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/stock_history_model.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sync_service.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<ProductModel> _lowStockProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategoryId;

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<CategoryModel> get categories => _categories;
  
  // Get product count for a specific category
  int getProductCountForCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId && p.isActive).length;
  }
  List<ProductModel> get lowStockProducts => _lowStockProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;

  List<ProductModel> get _filteredProducts {
    var filtered = _products.where((p) => p.isActive).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          (p.barcode?.toLowerCase().contains(query) ?? false)).toList();
    }

    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    return filtered;
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('[ProductProvider] loadProducts() called');
      
      // Simplified query - load ALL active products
      final results = await _db.query(
        AppConstants.productsTable,
        where: 'is_active = 1',
        orderBy: 'name ASC',
      );
      
      debugPrint('[ProductProvider] Found ${results.length} products in database');
      
      // Debug: Print each product
      for (var r in results) {
        debugPrint('[ProductProvider] Product: ${r['name']}, id: ${r['id']}, user_id: ${r['user_id']}, is_active: ${r['is_active']}');
      }

      _products = results.map((e) => ProductModel.fromJson(e)).toList();
      
      debugPrint('[ProductProvider] Loaded ${_products.length} products into memory');
      
      _updateLowStockProducts();
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load products: $e';
      debugPrint('[ProductProvider] Load products error: $e');
      debugPrint('[ProductProvider] Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.categoriesTable,
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );

      _categories = results.map((e) => CategoryModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load categories: $e';
      notifyListeners();
    }
  }

  Future<bool> addCategory(CategoryModel category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final newCategory = CategoryModel(
        id: _uuid.v4(),
        name: category.name,
        description: category.description,
        iconName: category.iconName,
        color: category.color,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.categoriesTable, newCategory.toJson());
      _categories.add(newCategory);
      notifyListeners();

      // Trigger sync
      _syncService.syncTable(AppConstants.categoriesTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final updated = category.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.categoriesTable,
        updated.toJson(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updated;
      }
      notifyListeners();

      _syncService.syncTable(AppConstants.categoriesTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId, {bool forceDelete = false}) async {
    try {
      // Check if category has products
      final products = await _db.query(
        AppConstants.productsTable,
        where: 'category_id = ? AND is_active = 1',
        whereArgs: [categoryId],
      );

      if (products.isNotEmpty && !forceDelete) {
        _errorMessage = 'Cannot delete category with existing products';
        notifyListeners();
        return false;
      }

      // If force delete, also delete associated products
      if (products.isNotEmpty && forceDelete) {
        await _db.update(
          AppConstants.productsTable,
          {
            'is_active': 0,
            'updated_at': DateTime.now().toIso8601String(),
            'sync_status': AppConstants.syncPending,
          },
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );
        // Remove from local list
        _products.removeWhere((p) => p.categoryId == categoryId);
      }

      await _db.update(
        AppConstants.categoriesTable,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': AppConstants.syncPending,
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();

      _syncService.syncTable(AppConstants.categoriesTable);
      _syncService.syncTable(AppConstants.productsTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(AppConstants.userIdKey);
      
      // Debug: Log the user ID
      debugPrint('Adding product with userId: $userId');

      final category = _categories.firstWhere(
        (c) => c.id == product.categoryId,
        orElse: () => CategoryModel(id: '', name: 'Uncategorized', createdAt: DateTime.now()),
      );

      final productId = _uuid.v4();
      final newProduct = ProductModel(
        id: productId,
        sku: product.sku,
        name: product.name,
        description: product.description,
        categoryId: product.categoryId,
        categoryName: category.name,
        costPrice: product.costPrice,
        salePrice: product.salePrice,
        quantity: product.quantity,
        lowStockThreshold: product.lowStockThreshold,
        barcode: product.barcode,
        imageUrl: product.imageUrl,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId ?? 'local_user', // Use fallback if userId is null
      );

      // Debug: Log product data
      debugPrint('Inserting product: ${newProduct.toJson()}');

      // Insert to database
      final result = await _db.insert(AppConstants.productsTable, newProduct.toJson());
      debugPrint('Database insert result: $result');

      // Verify insertion by querying back
      final verification = await _db.query(
        AppConstants.productsTable,
        where: 'id = ?',
        whereArgs: [productId],
      );
      debugPrint('Verification query result: ${verification.length} records found');

      // Add to memory list
      _products.add(newProduct);

      // Add stock history entry
      if (product.quantity > 0) {
        await _addStockHistory(
          productId: newProduct.id,
          productName: newProduct.name,
          operationType: AppConstants.stockIn,
          quantityBefore: 0,
          quantityChange: product.quantity,
          quantityAfter: product.quantity,
          notes: 'Initial stock',
        );
      }

      _updateLowStockProducts();
      notifyListeners();

      _syncService.syncTable(AppConstants.productsTable);

      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to add product: $e';
      debugPrint('Error adding product: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      final category = _categories.firstWhere(
        (c) => c.id == product.categoryId,
        orElse: () => CategoryModel(id: '', name: 'Uncategorized', createdAt: DateTime.now()),
      );

      final updated = product.copyWith(
        categoryName: category.name,
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.productsTable,
        updated.toJson(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updated;
      }

      _updateLowStockProducts();
      notifyListeners();

      _syncService.syncTable(AppConstants.productsTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update product: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _db.update(
        AppConstants.productsTable,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': AppConstants.syncPending,
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      _products.removeWhere((p) => p.id == productId);
      _updateLowStockProducts();
      notifyListeners();

      _syncService.syncTable(AppConstants.productsTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete product: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStock({
    required String productId,
    required int quantity,
    required String operationType,
    String? notes,
  }) async {
    try {
      debugPrint('[ProductProvider] updateStock called for productId: $productId');
      
      // Try to find product in memory first
      ProductModel? product;
      final productIndex = _products.indexWhere((p) => p.id == productId);
      
      if (productIndex != -1) {
        product = _products[productIndex];
      } else {
        // If not in memory, query database directly
        debugPrint('[ProductProvider] Product not in memory, querying database...');
        final results = await _db.query(
          AppConstants.productsTable,
          where: 'id = ?',
          whereArgs: [productId],
        );
        if (results.isNotEmpty) {
          product = ProductModel.fromJson(results.first);
        }
      }
      
      if (product == null) {
        debugPrint('[ProductProvider] Product not found: $productId');
        _errorMessage = 'Product not found';
        notifyListeners();
        return false;
      }
      
      final quantityBefore = product.quantity;
      int quantityAfter;

      switch (operationType) {
        case AppConstants.stockIn:
          quantityAfter = quantityBefore + quantity;
          break;
        case AppConstants.stockOut:
        case AppConstants.stockSale:
          quantityAfter = quantityBefore - quantity;
          break;
        case AppConstants.stockAdjust:
          quantityAfter = quantity;
          break;
        case AppConstants.stockReturn:
          quantityAfter = quantityBefore + quantity;
          break;
        default:
          quantityAfter = quantityBefore;
      }

      if (quantityAfter < 0) {
        _errorMessage = 'Insufficient stock';
        notifyListeners();
        return false;
      }

      await _db.update(
        AppConstants.productsTable,
        {
          'quantity': quantityAfter,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': AppConstants.syncPending,
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Add stock history
      await _addStockHistory(
        productId: productId,
        productName: product.name,
        operationType: operationType,
        quantityBefore: quantityBefore,
        quantityChange: operationType == AppConstants.stockAdjust 
            ? quantityAfter - quantityBefore 
            : (operationType == AppConstants.stockOut || operationType == AppConstants.stockSale 
                ? -quantity 
                : quantity),
        quantityAfter: quantityAfter,
        notes: notes,
      );

      // Update local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          quantity: quantityAfter,
          updatedAt: DateTime.now(),
        );
      }

      _updateLowStockProducts();
      notifyListeners();

      _syncService.syncTable(AppConstants.productsTable);
      _syncService.syncTable(AppConstants.stockHistoryTable);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update stock: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _addStockHistory({
    required String productId,
    required String productName,
    required String operationType,
    required int quantityBefore,
    required int quantityChange,
    required int quantityAfter,
    String? notes,
    String? referenceId,
    String? referenceType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);

    final history = StockHistoryModel(
      id: _uuid.v4(),
      productId: productId,
      productName: productName,
      operationType: operationType,
      quantityBefore: quantityBefore,
      quantityChange: quantityChange,
      quantityAfter: quantityAfter,
      referenceId: referenceId,
      referenceType: referenceType,
      notes: notes,
      operationDate: DateTime.now(),
      createdAt: DateTime.now(),
      syncStatus: AppConstants.syncPending,
      userId: userId,
    );

    await _db.insert(AppConstants.stockHistoryTable, history.toJson());
  }

  Future<List<StockHistoryModel>> getStockHistory(String productId) async {
    final results = await _db.query(
      AppConstants.stockHistoryTable,
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'operation_date DESC',
    );

    return results.map((e) => StockHistoryModel.fromJson(e)).toList();
  }

  void _updateLowStockProducts() {
    _lowStockProducts = _products.where((p) => p.isLowStock && p.isActive).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    notifyListeners();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  ProductModel? getProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode && p.isActive);
    } catch (e) {
      return null;
    }
  }

  ProductModel? getProductBySku(String sku) {
    try {
      return _products.firstWhere((p) => p.sku == sku && p.isActive);
    } catch (e) {
      return null;
    }
  }

  int get totalProducts => _products.where((p) => p.isActive).length;
  int get lowStockCount => _lowStockProducts.length;
  int get outOfStockCount => _products.where((p) => p.isOutOfStock && p.isActive).length;
  double get totalStockValue => _products.fold(0.0, (sum, p) => sum + (p.salePrice * p.quantity));
  double get totalCostValue => _products.fold(0.0, (sum, p) => sum + (p.costPrice * p.quantity));

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

