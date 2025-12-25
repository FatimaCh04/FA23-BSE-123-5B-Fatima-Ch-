import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/inventory/inventory_logs_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/reports/sales_report_screen.dart';
import '../../screens/reports/purchase_report_screen.dart';
import '../../screens/reports/item_sales_report_screen.dart';
import '../../screens/tax_discount/tax_screen.dart';
import '../../screens/tax_discount/discount_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/premium/premium_upgrade_screen.dart';
import '../../screens/auth/login_screen.dart';

class AppDrawer extends StatefulWidget {
  final int currentIndex;
  
  const AppDrawer({
    super.key,
    this.currentIndex = 0,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _inventoryExpanded = false;
  bool _reportsExpanded = false;
  bool _taxDiscountExpanded = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (user?.name.isNotEmpty ?? false) 
                          ? user!.name[0].toUpperCase() 
                          : 'U',
                      style: AppTheme.headingMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: AppTheme.titleLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.businessName ?? 'Smart POS',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Dashboard
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    isSelected: widget.currentIndex == 0,
                    onTap: () => _navigateTo(context, const DashboardScreen()),
                  ),

                  // Settings
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isSelected: widget.currentIndex == 1,
                    onTap: () => _navigateTo(context, const SettingsScreen()),
                  ),

                  const Divider(height: 24),

                  // Inventory Section (Expandable)
                  _buildExpandableSection(
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventory',
                    isExpanded: _inventoryExpanded,
                    onTap: () => setState(() => _inventoryExpanded = !_inventoryExpanded),
                    children: [
                      _buildSubMenuItem(
                        title: 'Inventory List',
                        isSelected: widget.currentIndex == 2,
                        onTap: () => _navigateTo(context, const InventoryScreen()),
                      ),
                      _buildSubMenuItem(
                        title: 'Inventory Logs',
                        isSelected: widget.currentIndex == 3,
                        onTap: () => _navigateTo(context, const InventoryLogsScreen()),
                      ),
                    ],
                  ),

                  // Reports Section (Expandable)
                  _buildExpandableSection(
                    icon: Icons.bar_chart_outlined,
                    title: 'Reports',
                    isExpanded: _reportsExpanded,
                    onTap: () => setState(() => _reportsExpanded = !_reportsExpanded),
                    children: [
                      _buildSubMenuItem(
                        title: 'Sales Report',
                        isSelected: widget.currentIndex == 4,
                        onTap: () => _navigateTo(context, const SalesReportScreen()),
                      ),
                      _buildSubMenuItem(
                        title: 'Purchase Report',
                        isSelected: widget.currentIndex == 5,
                        onTap: () => _navigateTo(context, const PurchaseReportScreen()),
                      ),
                      _buildSubMenuItem(
                        title: 'Item Sales Report',
                        isSelected: widget.currentIndex == 6,
                        onTap: () => _navigateTo(context, const ItemSalesReportScreen()),
                      ),
                    ],
                  ),

                  // Tax & Discount Section (Expandable)
                  _buildExpandableSection(
                    icon: Icons.local_offer_outlined,
                    title: 'Tax & Discount',
                    isExpanded: _taxDiscountExpanded,
                    onTap: () => setState(() => _taxDiscountExpanded = !_taxDiscountExpanded),
                    children: [
                      _buildSubMenuItem(
                        title: 'Tax',
                        isSelected: widget.currentIndex == 7,
                        onTap: () => _navigateTo(context, const TaxScreen()),
                      ),
                      _buildSubMenuItem(
                        title: 'Discount',
                        isSelected: widget.currentIndex == 8,
                        onTap: () => _navigateTo(context, const DiscountScreen()),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Premium Upgrade
                  _buildMenuItem(
                    icon: Icons.diamond_outlined,
                    title: 'Premium Upgrade',
                    isSelected: widget.currentIndex == 9,
                    isPremium: true,
                    onTap: () => _navigateTo(context, const PremiumUpgradeScreen()),
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context, authService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isPremium 
              ? AppTheme.successColor 
              : isSelected 
                  ? AppTheme.primaryColor 
                  : AppTheme.textSecondary,
        ),
        title: Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            color: isPremium 
                ? AppTheme.successColor 
                : isSelected 
                    ? AppTheme.primaryColor 
                    : AppTheme.textPrimary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isExpanded 
                ? AppTheme.primaryColor.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isExpanded 
                  ? AppTheme.primaryColor 
                  : AppTheme.textSecondary,
            ),
            title: Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: isExpanded 
                    ? AppTheme.primaryColor 
                    : AppTheme.textPrimary,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.textSecondary,
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.bar_chart,
          size: 20,
          color: isSelected 
              ? AppTheme.primaryColor 
              : AppTheme.textSecondary,
        ),
        title: Text(
          title,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected 
                ? AppTheme.primaryColor 
                : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    // Use push instead of pushReplacement so back button works
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthService authService) async {
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

    if (result == true && context.mounted) {
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

