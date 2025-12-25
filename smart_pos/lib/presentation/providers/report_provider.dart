import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';

// Debug flag - set to false in production
const bool _enableDebugLogs = true;

void _log(String message) {
  if (_enableDebugLogs) {
    debugPrint('[ReportProvider] $message');
  }
}

class ReportProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isLoading = false;
  String? _errorMessage;

  // Sales Report Data
  List<SaleModel> _salesData = [];
  double _totalSales = 0.0;
  double _totalProfit = 0.0;
  int _totalTransactions = 0;
  double _averageSale = 0.0;

  // Stock Report Data
  List<ProductModel> _stockData = [];
  double _totalStockValue = 0.0;
  double _totalCostValue = 0.0;
  int _lowStockCount = 0;
  int _outOfStockCount = 0;

  // Customer Report Data
  List<CustomerModel> _customerData = [];
  double _totalReceivables = 0.0;
  int _activeCustomers = 0;

  // Daily/Monthly breakdown
  Map<String, double> _dailySales = {};
  Map<String, double> _monthlySales = {};
  Map<String, int> _salesByPaymentMethod = {};
  Map<String, double> _salesByCategory = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCustomers = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SaleModel> get salesData => _salesData;
  double get totalSales => _totalSales;
  double get totalProfit => _totalProfit;
  int get totalTransactions => _totalTransactions;
  double get averageSale => _averageSale;
  List<ProductModel> get stockData => _stockData;
  double get totalStockValue => _totalStockValue;
  double get totalCostValue => _totalCostValue;
  int get lowStockCount => _lowStockCount;
  int get outOfStockCount => _outOfStockCount;
  List<CustomerModel> get customerData => _customerData;
  double get totalReceivables => _totalReceivables;
  int get activeCustomers => _activeCustomers;
  Map<String, double> get dailySales => _dailySales;
  Map<String, double> get monthlySales => _monthlySales;
  Map<String, int> get salesByPaymentMethod => _salesByPaymentMethod;
  Map<String, double> get salesByCategory => _salesByCategory;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get topCustomers => _topCustomers;

  Future<void> loadDailyReport(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get sales for the day
      final salesResults = await _db.query(
        AppConstants.salesTable,
        where: 'user_id = ? AND sale_date >= ? AND sale_date < ? AND is_void = 0',
        whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'sale_date DESC',
      );

      _salesData = await Future.wait(salesResults.map((sale) async {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        return SaleModel.fromJson({...sale, 'items': items});
      }));

      _calculateSalesMetrics();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load daily report: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyReport(int year, int month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      // Get sales for the month
      final salesResults = await _db.query(
        AppConstants.salesTable,
        where: 'user_id = ? AND sale_date >= ? AND sale_date < ? AND is_void = 0',
        whereArgs: [userId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
        orderBy: 'sale_date DESC',
      );

      _salesData = await Future.wait(salesResults.map((sale) async {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        return SaleModel.fromJson({...sale, 'items': items});
      }));

      _calculateSalesMetrics();
      await _calculateDailyBreakdown(startOfMonth, endOfMonth);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load monthly report: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDateRangeReport(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

      // Get sales for the range
      final salesResults = await _db.query(
        AppConstants.salesTable,
        where: 'user_id = ? AND sale_date >= ? AND sale_date < ? AND is_void = 0',
        whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
        orderBy: 'sale_date DESC',
      );

      _salesData = await Future.wait(salesResults.map((sale) async {
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        return SaleModel.fromJson({...sale, 'items': items});
      }));

      _calculateSalesMetrics();
      await _calculateDailyBreakdown(start, end);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load report: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.productsTable,
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'quantity ASC',
      );

      _stockData = results.map((e) => ProductModel.fromJson(e)).toList();
      
      _totalStockValue = _stockData.fold(0.0, (sum, p) => sum + (p.salePrice * p.quantity));
      _totalCostValue = _stockData.fold(0.0, (sum, p) => sum + (p.costPrice * p.quantity));
      _lowStockCount = _stockData.where((p) => p.isLowStock).length;
      _outOfStockCount = _stockData.where((p) => p.isOutOfStock).length;

      // Sales by category
      _salesByCategory = {};
      for (final product in _stockData) {
        final categoryName = product.categoryName ?? 'Uncategorized';
        _salesByCategory[categoryName] = (_salesByCategory[categoryName] ?? 0) + (product.salePrice * product.quantity);
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load stock report: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCustomerReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.customersTable,
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'total_purchases DESC',
      );

      _customerData = results.map((e) => CustomerModel.fromJson(e)).toList();
      
      _totalReceivables = _customerData.fold(0.0, (sum, c) => sum + c.outstandingBalance);
      _activeCustomers = _customerData.length;

      // Top customers by purchase
      _topCustomers = _customerData
          .take(10)
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'totalPurchases': c.totalPurchases,
                'outstanding': c.outstandingBalance,
              })
          .toList();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load customer report: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTopProducts({DateTime? startDate, DateTime? endDate}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      String whereClause = 'si.sale_id IN (SELECT id FROM ${AppConstants.salesTable} WHERE user_id = ? AND is_void = 0';
      List<dynamic> whereArgs = [userId];

      if (startDate != null) {
        whereClause += ' AND sale_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClause += ' AND sale_date < ?';
        whereArgs.add(endDate.add(const Duration(days: 1)).toIso8601String());
      }
      whereClause += ')';

      final results = await _db.rawQuery('''
        SELECT 
          si.product_id,
          si.product_name,
          SUM(si.quantity) as total_quantity,
          SUM(si.total_price) as total_revenue,
          SUM((si.unit_price - si.cost_price - si.discount_amount) * si.quantity) as total_profit
        FROM ${AppConstants.saleItemsTable} si
        WHERE $whereClause
        GROUP BY si.product_id
        ORDER BY total_revenue DESC
        LIMIT 10
      ''', whereArgs);

      _topProducts = results.map((r) => {
        'productId': r['product_id'],
        'productName': r['product_name'],
        'quantity': r['total_quantity'],
        'revenue': r['total_revenue'],
        'profit': r['total_profit'],
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load top products: $e');
    }
  }

  void _calculateSalesMetrics() {
    _totalSales = _salesData.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    _totalProfit = _salesData.fold(0.0, (sum, sale) => sum + sale.totalProfit);
    _totalTransactions = _salesData.length;
    _averageSale = _totalTransactions > 0 ? _totalSales / _totalTransactions : 0.0;

    // Payment method breakdown
    _salesByPaymentMethod = {};
    for (final sale in _salesData) {
      _salesByPaymentMethod[sale.paymentMethod] = 
          (_salesByPaymentMethod[sale.paymentMethod] ?? 0) + 1;
    }
  }

  Future<void> _calculateDailyBreakdown(DateTime start, DateTime end) async {
    _dailySales = {};
    
    for (final sale in _salesData) {
      final dateKey = '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';
      _dailySales[dateKey] = (_dailySales[dateKey] ?? 0) + sale.totalAmount;
    }
  }

  // Dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      
      _log('getDashboardSummary called with userId: $userId');
      
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final monthStart = DateTime(today.year, today.month, 1);

      // First, let's get ALL products count without user filter for debugging
      final allProductsDebug = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM ${AppConstants.productsTable}
        WHERE is_active = 1
      ''');
      _log('All products count (no user filter): ${allProductsDebug.first['count']}');

      // Get all products with their user_ids for debugging
      final productDetails = await _db.rawQuery('''
        SELECT id, name, user_id, is_active FROM ${AppConstants.productsTable}
        LIMIT 10
      ''');
      _log('Product details: $productDetails');

      // Build user filter - SIMPLIFIED: just get all active products
      // Products count - get ALL active products regardless of user
      final productCount = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM ${AppConstants.productsTable}
        WHERE is_active = 1
      ''');
      _log('Products with is_active=1: ${productCount.first['count']}');

      // Low stock count
      final lowStock = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM ${AppConstants.productsTable}
        WHERE is_active = 1 AND quantity <= low_stock_threshold
      ''');

      // Customer count - get ALL active customers
      final customerCount = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM ${AppConstants.customersTable}
        WHERE is_active = 1
      ''');

      // Total receivables
      final receivables = await _db.rawQuery('''
        SELECT COALESCE(SUM(outstanding_balance), 0) as total FROM ${AppConstants.customersTable}
        WHERE is_active = 1
      ''');

      // Today's sales - simplified
      final todayResults = await _db.rawQuery('''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(total_amount), 0) as total
        FROM ${AppConstants.salesTable}
        WHERE sale_date >= ? AND is_void = 0
      ''', [todayStart.toIso8601String()]);

      // Month's sales - simplified
      final monthResults = await _db.rawQuery('''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(total_amount), 0) as total
        FROM ${AppConstants.salesTable}
        WHERE sale_date >= ? AND is_void = 0
      ''', [monthStart.toIso8601String()]);

      final result = {
        'todaySales': todayResults.first['total'] ?? 0.0,
        'todayTransactions': todayResults.first['count'] ?? 0,
        'monthSales': monthResults.first['total'] ?? 0.0,
        'monthTransactions': monthResults.first['count'] ?? 0,
        'productCount': productCount.first['count'] ?? 0,
        'lowStockCount': lowStock.first['count'] ?? 0,
        'customerCount': customerCount.first['count'] ?? 0,
        'totalReceivables': receivables.first['total'] ?? 0.0,
      };
      
      _log('Dashboard summary result: $result');
      return result;
    } catch (e, stackTrace) {
      _log('Error in getDashboardSummary: $e');
      _log('Stack trace: $stackTrace');
      return {
        'todaySales': 0.0,
        'todayTransactions': 0,
        'monthSales': 0.0,
        'monthTransactions': 0,
        'productCount': 0,
        'lowStockCount': 0,
        'customerCount': 0,
        'totalReceivables': 0.0,
      };
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

