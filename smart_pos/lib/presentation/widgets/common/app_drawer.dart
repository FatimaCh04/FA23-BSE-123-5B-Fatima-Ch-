import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/products/products_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/customers/customers_screen.dart';
import '../../screens/ledger/ledger_screen.dart';
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
import '../../screens/vendors/vendors_screen.dart';
import '../../screens/purchases/purchases_screen.dart';

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
  bool _itemsExpanded = false;
  bool _inventoryExpanded = false;
  bool _reportsExpanded = false;
  bool _taxDiscountExpanded = false;
  String? _profilePicturePath;

  // Theme Colors
  static const Color _primaryTeal = Color(0xFF00796B);
  static const Color _darkTeal = Color(0xFF004D40);
  static const Color _lightTeal = Color(0xFF4DB6AC);

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profilePicturePath = prefs.getString('profile_picture_path');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          // Modern Header with Gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryTeal, _darkTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar with Picture
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: _profilePicturePath != null && _profilePicturePath!.isNotEmpty
                            ? DecorationImage(
                                image: FileImage(File(_profilePicturePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePicturePath == null || _profilePicturePath!.isEmpty
                          ? Center(
                              child: Text(
                                (user?.name.isNotEmpty ?? false) 
                                    ? user!.name[0].toUpperCase() 
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryTeal,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // User Name
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Business Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.store,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user?.businessName ?? 'Mobile Shop POS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // Main Section Label
                _buildSectionLabel('MAIN MENU'),
                
                // Dashboard
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: widget.currentIndex == 0,
                  onTap: () => _navigateTo(context, const DashboardScreen()),
                ),

                // Items Section (Expandable)
                _buildExpandableSection(
                  icon: Icons.inventory_2_rounded,
                  title: 'Items',
                  isExpanded: _itemsExpanded,
                  onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
                  children: [
                    _buildSubMenuItem(
                      title: 'Categories',
                      icon: Icons.category_rounded,
                      isSelected: widget.currentIndex == 1,
                      onTap: () => _navigateTo(context, const CategoriesScreen()),
                    ),
                    _buildSubMenuItem(
                      title: 'Products',
                      icon: Icons.shopping_bag_rounded,
                      isSelected: widget.currentIndex == 2,
                      onTap: () => _navigateTo(context, const ProductsScreen()),
                    ),
                  ],
                ),

                // Customers
                _buildMenuItem(
                  icon: Icons.people_rounded,
                  title: 'Customers',
                  isSelected: widget.currentIndex == 3,
                  onTap: () => _navigateTo(context, const CustomersScreen()),
                ),

                // Ledger
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Ledger',
                  isSelected: widget.currentIndex == 4,
                  onTap: () => _navigateTo(context, const LedgerScreen()),
                ),

                // Vendors
                _buildMenuItem(
                  icon: Icons.local_shipping_rounded,
                  title: 'Vendors',
                  isSelected: widget.currentIndex == 13,
                  onTap: () => _navigateTo(context, const VendorsScreen()),
                ),

                // Purchases
                _buildMenuItem(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Purchases',
                  isSelected: widget.currentIndex == 14,
                  onTap: () => _navigateTo(context, const PurchasesScreen()),
                ),

                const SizedBox(height: 8),
                _buildSectionLabel('MANAGEMENT'),

                // Inventory Section (Expandable)
                _buildExpandableSection(
                  icon: Icons.warehouse_rounded,
                  title: 'Inventory',
                  isExpanded: _inventoryExpanded,
                  onTap: () => setState(() => _inventoryExpanded = !_inventoryExpanded),
                  children: [
                    _buildSubMenuItem(
                      title: 'Stock List',
                      icon: Icons.list_alt_rounded,
                      isSelected: widget.currentIndex == 6,
                      onTap: () => _navigateTo(context, const InventoryScreen()),
                    ),
                    _buildSubMenuItem(
                      title: 'Stock History',
                      icon: Icons.history_rounded,
                      isSelected: widget.currentIndex == 7,
                      onTap: () => _navigateTo(context, const InventoryLogsScreen()),
                    ),
                  ],
                ),

                // Reports Section (Expandable)
                _buildExpandableSection(
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  isExpanded: _reportsExpanded,
                  onTap: () => setState(() => _reportsExpanded = !_reportsExpanded),
                  children: [
                    _buildSubMenuItem(
                      title: 'Sales Report',
                      icon: Icons.point_of_sale_rounded,
                      isSelected: widget.currentIndex == 8,
                      onTap: () => _navigateTo(context, const SalesReportScreen()),
                    ),
                    _buildSubMenuItem(
                      title: 'Purchase Report',
                      icon: Icons.shopping_cart_rounded,
                      isSelected: widget.currentIndex == 9,
                      onTap: () => _navigateTo(context, const PurchaseReportScreen()),
                    ),
                    _buildSubMenuItem(
                      title: 'Item Sales',
                      icon: Icons.analytics_rounded,
                      isSelected: widget.currentIndex == 10,
                      onTap: () => _navigateTo(context, const ItemSalesReportScreen()),
                    ),
                  ],
                ),

                // Tax & Discount Section (Expandable)
                _buildExpandableSection(
                  icon: Icons.local_offer_rounded,
                  title: 'Tax & Discount',
                  isExpanded: _taxDiscountExpanded,
                  onTap: () => setState(() => _taxDiscountExpanded = !_taxDiscountExpanded),
                  children: [
                    _buildSubMenuItem(
                      title: 'Tax Settings',
                      icon: Icons.receipt_long_rounded,
                      isSelected: widget.currentIndex == 11,
                      onTap: () => _navigateTo(context, const TaxScreen()),
                    ),
                    _buildSubMenuItem(
                      title: 'Discounts',
                      icon: Icons.discount_rounded,
                      isSelected: widget.currentIndex == 12,
                      onTap: () => _navigateTo(context, const DiscountScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                _buildSectionLabel('OTHER'),

                // Settings
                _buildMenuItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  isSelected: widget.currentIndex == 5,
                  onTap: () => _navigateTo(context, const SettingsScreen()),
                ),

                // Premium Upgrade
                _buildPremiumItem(
                  onTap: () => _navigateTo(context, const PremiumUpgradeScreen()),
                ),
              ],
            ),
          ),

          // Bottom Logout Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: InkWell(
              onTap: () => _showLogoutDialog(context, authService),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? _primaryTeal.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: _primaryTeal.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected 
                ? _primaryTeal.withOpacity(0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? _primaryTeal : Colors.grey.shade600,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? _primaryTeal : Colors.grey.shade800,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            color: isExpanded ? _primaryTeal.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isExpanded 
                    ? _primaryTeal.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isExpanded ? _primaryTeal : Colors.grey.shade600,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                color: isExpanded ? _primaryTeal : Colors.grey.shade800,
              ),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isExpanded ? _primaryTeal : Colors.grey.shade500,
              ),
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 20),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _primaryTeal.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(children: children),
          ),
          crossFadeState: isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    IconData icon = Icons.circle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? _primaryTeal.withOpacity(0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? _primaryTeal : Colors.grey.shade500,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? _primaryTeal : Colors.grey.shade700,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildPremiumItem({required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA726).withOpacity(0.15),
            const Color(0xFFFF7043).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA726).withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: const Text(
          'Go Premium',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE65100),
          ),
        ),
        subtitle: Text(
          'Unlock all features',
          style: TextStyle(
            fontSize: 11,
            color: Colors.orange.shade600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Color(0xFFFFA726),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthService authService) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
