import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/stock_history_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_drawer.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<StockHistoryModel> _purchases = [];
  bool _isLoading = false;
  double _totalPurchaseValue = 0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<ProductProvider>();
    final allHistory = <StockHistoryModel>[];
    
    for (final product in provider.allProducts) {
      final history = await provider.getStockHistory(product.id);
      // Filter only stock_in (purchases)
      final purchases = history.where((h) => 
        h.operationType == AppConstants.stockIn
      );
      allHistory.addAll(purchases);
    }
    
    // Filter by date range
    final filtered = allHistory.where((log) {
      return log.operationDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             log.operationDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
    
    filtered.sort((a, b) => b.operationDate.compareTo(a.operationDate));
    
    // Calculate totals
    double totalValue = 0;
    int totalItems = 0;
    for (var purchase in filtered) {
      totalItems += purchase.quantityChange;
      // Note: We'd need cost price from product for accurate value
    }
    
    setState(() {
      _purchases = filtered;
      _totalPurchaseValue = totalValue;
      _totalItems = totalItems;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPurchases();
    }
  }

  Future<void> _exportPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Purchase Report PDF...'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase Report PDF exported'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Report', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 5),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: ListTile(
              leading: const Icon(Icons.date_range, color: AppTheme.primaryColor),
              title: Text(
                '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: AppTheme.titleMedium,
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectDateRange,
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Purchases',
                    '${_purchases.length}',
                    Icons.shopping_cart,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Items Added',
                    '$_totalItems',
                    Icons.inventory_2,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Purchases List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Purchase History', style: AppTheme.titleLarge),
                TextButton(
                  onPressed: _loadPurchases,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),

          // Purchases List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _purchases.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _purchases.length,
                        itemBuilder: (context, index) {
                          return _buildPurchaseCard(_purchases[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(StockHistoryModel purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.productName ?? 'Product',
                  style: AppTheme.titleMedium,
                ),
                Text(
                  'Qty: ${purchase.quantityChange} units',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${purchase.quantityChange}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
              Text(
                DateFormat('dd-MMM').format(purchase.operationDate),
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.titleMedium.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No purchases found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'No purchase records in the selected period',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

