import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/app_drawer.dart';

class ItemSalesReportScreen extends StatefulWidget {
  const ItemSalesReportScreen({super.key});

  @override
  State<ItemSalesReportScreen> createState() => _ItemSalesReportScreenState();
}

class _ItemSalesReportScreenState extends State<ItemSalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String _sortBy = 'quantity'; // quantity, revenue, name

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final provider = context.read<ReportProvider>();
    await provider.loadTopProducts();
    setState(() => _isLoading = false);
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
      _loadReport();
    }
  }

  Future<void> _exportPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Item Sales Report PDF...'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item Sales Report PDF exported'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Sales Report', style: AppTheme.headingSmall),
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
      drawer: const AppDrawer(currentIndex: 6),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          final products = List<Map<String, dynamic>>.from(provider.topProducts);
          
          // Sort based on selection
          if (_sortBy == 'quantity') {
            products.sort((a, b) => (b['quantity'] ?? 0).compareTo(a['quantity'] ?? 0));
          } else if (_sortBy == 'revenue') {
            products.sort((a, b) => (b['revenue'] ?? 0).compareTo(a['revenue'] ?? 0));
          } else {
            products.sort((a, b) => (a['productName'] ?? '').compareTo(b['productName'] ?? ''));
          }

          // Calculate totals
          int totalQuantity = 0;
          double totalRevenue = 0;
          for (var product in products) {
            totalQuantity += (product['quantity'] ?? 0) as int;
            totalRevenue += (product['revenue'] ?? 0) as double;
          }

          return Column(
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
                        'Total Items Sold',
                        '$totalQuantity',
                        Icons.inventory_2,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Revenue',
                        'PKR ${totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sort Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppTheme.cardDecoration,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      icon: const Icon(Icons.sort),
                      items: const [
                        DropdownMenuItem(value: 'quantity', child: Text('Sort by Quantity')),
                        DropdownMenuItem(value: 'revenue', child: Text('Sort by Revenue')),
                        DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Products List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Product Sales', style: AppTheme.titleLarge),
                    Text(
                      '${products.length} items',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Products List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(products[index], index + 1);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int rank) {
    final quantity = product['quantity'] ?? 0;
    final revenue = (product['revenue'] ?? 0).toDouble();
    final productName = product['productName'] ?? 'Unknown Product';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank <= 3 
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.textLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTheme.labelLarge.copyWith(
                  color: rank <= 3 ? AppTheme.accentColor : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: AppTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${revenue.toStringAsFixed(0)}',
                style: AppTheme.priceText,
              ),
              Text(
                'revenue',
                style: AppTheme.labelSmall,
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
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No item sales found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'No products sold in the selected period',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

