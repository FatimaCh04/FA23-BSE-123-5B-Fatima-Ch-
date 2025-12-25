import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../products/products_screen.dart';
import '../inventory/inventory_screen.dart';
import '../pos/pos_screen.dart';
import '../customers/customers_screen.dart';
import '../ledger/ledger_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../backup/backup_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load all required data
    final productProvider = context.read<ProductProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final posProvider = context.read<POSProvider>();
    final reportProvider = context.read<ReportProvider>();

    await Future.wait([
      productProvider.loadProducts(),
      productProvider.loadCategories(),
      customerProvider.loadCustomers(),
      posProvider.loadTodaySales(),
      posProvider.loadRecentSales(),
    ]);

    _dashboardData = await reportProvider.getDashboardSummary();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final connectivityService = context.watch<ConnectivityService>();
    final syncService = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Connectivity Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildStatusIndicator(
              icon: connectivityService.isOnline
                  ? Icons.wifi
                  : Icons.wifi_off,
              color: connectivityService.isOnline
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
              label: connectivityService.isOnline ? 'Online' : 'Offline',
            ),
          ),
          // Sync Status
          if (syncService.pendingSyncCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildStatusIndicator(
                icon: Icons.sync,
                color: AppTheme.infoColor,
                label: '${syncService.pendingSyncCount}',
                onTap: () => syncService.syncAll(),
              ),
            ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppTheme.primaryColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Welcome Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authService.currentUser?.name ?? 'User',
                        style: AppTheme.headingMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Today's Stats
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.gradientCardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Today's Sales",
                                        style: AppTheme.titleMedium.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_dashboardData['todayTransactions'] ?? 0} orders',
                                          style: AppTheme.labelMedium.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'PKR ${(_dashboardData['todaySales'] ?? 0.0).toStringAsFixed(0)}',
                                    style: AppTheme.headingLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Quick Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Products',
                                    '${_dashboardData['productCount'] ?? 0}',
                                    Icons.inventory_2_outlined,
                                    AppTheme.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Low Stock',
                                    '${_dashboardData['lowStockCount'] ?? 0}',
                                    Icons.warning_amber_rounded,
                                    AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Customers',
                                    '${_dashboardData['customerCount'] ?? 0}',
                                    Icons.people_outline,
                                    AppTheme.infoColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Receivables',
                                    'PKR ${(_dashboardData['totalReceivables'] ?? 0.0).toStringAsFixed(0)}',
                                    Icons.account_balance_wallet_outlined,
                                    AppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: AppTheme.titleLarge),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildActionButton(
                            'New Sale',
                            Icons.point_of_sale,
                            AppTheme.primaryColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const POSScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Products',
                            Icons.inventory_2,
                            AppTheme.primaryLight,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProductsScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Inventory',
                            Icons.warehouse,
                            AppTheme.accentColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InventoryScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Customers',
                            Icons.people,
                            AppTheme.infoColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomersScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Ledger',
                            Icons.account_balance,
                            AppTheme.successColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LedgerScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Reports',
                            Icons.analytics,
                            AppTheme.errorColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Backup',
                            Icons.backup,
                            AppTheme.primaryDark,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BackupScreen()),
                            ),
                          ),
                          _buildActionButton(
                            'Logout',
                            Icons.logout,
                            AppTheme.textSecondary,
                            () => _showLogoutDialog(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Sales
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Sales', style: AppTheme.titleLarge),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            ),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Recent Sales List
              Consumer<POSProvider>(
                builder: (context, posProvider, _) {
                  final recentSales = posProvider.recentSales.take(5).toList();
                  
                  if (recentSales.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sales yet',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final sale = recentSales[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sale.invoiceNumber,
                                        style: AppTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sale.customerName ?? 'Walk-in',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'PKR ${sale.totalAmount.toStringAsFixed(0)}',
                                      style: AppTheme.priceText,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sale.isPaid
                                            ? AppTheme.successColor.withOpacity(0.1)
                                            : AppTheme.warningColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        sale.isPaid ? 'Paid' : 'Due',
                                        style: AppTheme.labelMedium.copyWith(
                                          color: sale.isPaid
                                              ? AppTheme.successColor
                                              : AppTheme.warningColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: recentSales.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const POSScreen()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

