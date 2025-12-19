import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/report_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    final provider = context.read<ReportProvider>();
    provider.loadDailyReport(_selectedDate);
    provider.loadStockReport();
    provider.loadCustomerReport();
    provider.loadTopProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports', style: AppTheme.headingSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Monthly'),
            Tab(text: 'Stock'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReport(),
          _buildMonthlyReport(),
          _buildStockReport(),
          _buildCustomerReport(),
        ],
      ),
    );
  }

  Widget _buildDailyReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Date Selector
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate =
                            _selectedDate.subtract(const Duration(days: 1));
                      });
                      provider.loadDailyReport(_selectedDate);
                    },
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context, provider),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: AppTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedDate.isBefore(
                            DateTime.now().subtract(const Duration(days: 1)))
                        ? () {
                            setState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 1));
                            });
                            provider.loadDailyReport(_selectedDate);
                          }
                        : null,
                  ),
                ],
              ),
            ),

            // Stats Cards
            if (!provider.isLoading) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Sales',
                        'PKR ${provider.totalSales.toStringAsFixed(0)}',
                        Icons.trending_up,
                        AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Transactions',
                        '${provider.totalTransactions}',
                        Icons.receipt_long,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Profit',
                        'PKR ${provider.totalProfit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Avg Sale',
                        'PKR ${provider.averageSale.toStringAsFixed(0)}',
                        Icons.analytics,
                        AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Sales List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.salesData.isEmpty
                      ? _buildEmptyState('No sales on this day')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.salesData.length,
                          itemBuilder: (context, index) {
                            final sale = provider.salesData[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration,
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.receipt,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sale.invoiceNumber,
                                          style: AppTheme.titleMedium,
                                        ),
                                        Text(
                                          '${sale.customerName ?? "Walk-in"} • ${sale.totalItems} items',
                                          style: AppTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'PKR ${sale.totalAmount.toStringAsFixed(0)}',
                                    style: AppTheme.priceText,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Month Selector
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 1) {
                          _selectedMonth = 12;
                          _selectedYear--;
                        } else {
                          _selectedMonth--;
                        }
                      });
                      provider.loadMonthlyReport(_selectedYear, _selectedMonth);
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy')
                        .format(DateTime(_selectedYear, _selectedMonth)),
                    style: AppTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_selectedYear < DateTime.now().year ||
                            (_selectedYear == DateTime.now().year &&
                                _selectedMonth < DateTime.now().month))
                        ? () {
                            setState(() {
                              if (_selectedMonth == 12) {
                                _selectedMonth = 1;
                                _selectedYear++;
                              } else {
                                _selectedMonth++;
                              }
                            });
                            provider.loadMonthlyReport(
                                _selectedYear, _selectedMonth);
                          }
                        : null,
                  ),
                ],
              ),
            ),

            // Load monthly data button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () =>
                    provider.loadMonthlyReport(_selectedYear, _selectedMonth),
                child: const Text('Load Monthly Report'),
              ),
            ),

            // Stats
            if (!provider.isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Sales',
                        'PKR ${provider.totalSales.toStringAsFixed(0)}',
                        Icons.trending_up,
                        AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Profit',
                        'PKR ${provider.totalProfit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Transactions',
                        '${provider.totalTransactions}',
                        Icons.receipt_long,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Avg Sale',
                        'PKR ${provider.averageSale.toStringAsFixed(0)}',
                        Icons.analytics,
                        AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Daily breakdown
            if (provider.dailySales.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Daily Breakdown', style: AppTheme.titleLarge),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.dailySales.length,
                  itemBuilder: (context, index) {
                    final entry = provider.dailySales.entries.toList()[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: AppTheme.bodyMedium),
                          Text(
                            'PKR ${entry.value.toStringAsFixed(0)}',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStockReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Stock Value',
                      'PKR ${provider.totalStockValue.toStringAsFixed(0)}',
                      Icons.inventory_2,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Cost Value',
                      'PKR ${provider.totalCostValue.toStringAsFixed(0)}',
                      Icons.price_check,
                      AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      '${provider.lowStockCount}',
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Out of Stock',
                      '${provider.outOfStockCount}',
                      Icons.error_outline,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),

              // Category Breakdown
              const SizedBox(height: 24),
              Text('Stock by Category', style: AppTheme.titleLarge),
              const SizedBox(height: 16),
              ...provider.salesByCategory.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: AppTheme.bodyMedium),
                      Text(
                        'PKR ${entry.value.toStringAsFixed(0)}',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Top Products
              if (provider.topProducts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Top Selling Products', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                ...provider.topProducts.take(5).map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['productName'] ?? '',
                                style: AppTheme.labelLarge,
                              ),
                              Text(
                                'Sold: ${product['quantity']} units',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'PKR ${(product['revenue'] ?? 0).toStringAsFixed(0)}',
                          style: AppTheme.priceText,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Customers',
                      '${provider.activeCustomers}',
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Receivables',
                      'PKR ${provider.totalReceivables.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),

              // Top Customers
              if (provider.topCustomers.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Top Customers by Purchase', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                ...provider.topCustomers.map((customer) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            (customer['name'] as String)[0].toUpperCase(),
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer['name'] ?? '',
                                style: AppTheme.titleMedium,
                              ),
                              if ((customer['outstanding'] ?? 0) > 0)
                                Text(
                                  'Outstanding: PKR ${(customer['outstanding']).toStringAsFixed(0)}',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'PKR ${(customer['totalPurchases'] ?? 0).toStringAsFixed(0)}',
                          style: AppTheme.priceText,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ReportProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      provider.loadDailyReport(picked);
    }
  }
}

