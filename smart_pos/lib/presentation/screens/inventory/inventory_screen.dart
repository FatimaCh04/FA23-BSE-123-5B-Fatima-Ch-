import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_history_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warehouse, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Inventory',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Stock'),
            Tab(text: 'Low Stock'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStockTab(),
          _buildLowStockTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildStockTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Products',
                      '${provider.totalProducts}',
                      Icons.inventory_2_outlined,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Stock Value',
                      'PKR ${provider.totalStockValue.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_outlined,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: provider.allProducts.isEmpty
                  ? _buildEmptyState('No products found')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.allProducts.length,
                      itemBuilder: (context, index) {
                        final product = provider.allProducts[index];
                        return _buildStockCard(product, provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final lowStock = provider.lowStockProducts;

        if (lowStock.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppTheme.successColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'All products are well stocked!',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Alert Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${lowStock.length} products need restocking',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Low Stock List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: lowStock.length,
                itemBuilder: (context, index) {
                  final product = lowStock[index];
                  return _buildStockCard(product, provider, isLowStock: true);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<dynamic>>(
          future: _loadAllStockHistory(provider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState('No stock history');
            }

            final history = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index] as StockHistoryModel;
                return _buildHistoryCard(item);
              },
            );
          },
        );
      },
    );
  }

  Future<List<StockHistoryModel>> _loadAllStockHistory(
      ProductProvider provider) async {
    final allHistory = <StockHistoryModel>[];
    for (final product in provider.allProducts) {
      final history = await provider.getStockHistory(product.id);
      allHistory.addAll(history);
    }
    allHistory.sort((a, b) => b.operationDate.compareTo(a.operationDate));
    return allHistory.take(50).toList();
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(
    ProductModel product,
    ProductProvider provider, {
    bool isLowStock = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.isOutOfStock
              ? AppTheme.errorColor.withOpacity(0.3)
              : product.isLowStock
                  ? AppTheme.warningColor.withOpacity(0.3)
                  : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.sku}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Stock Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: product.isOutOfStock
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : product.isLowStock
                          ? AppTheme.warningColor.withOpacity(0.1)
                          : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Qty: ${product.quantity}',
                  style: AppTheme.labelMedium.copyWith(
                    color: product.isOutOfStock
                        ? AppTheme.errorColor
                        : product.isLowStock
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStockButton(
                    Icons.remove,
                    AppTheme.errorColor,
                    () => _showStockOutDialog(product, provider),
                  ),
                  const SizedBox(width: 8),
                  _buildStockButton(
                    Icons.add,
                    AppTheme.successColor,
                    () => _showStockInDialog(product, provider),
                  ),
                  const SizedBox(width: 8),
                  _buildStockButton(
                    Icons.edit,
                    AppTheme.primaryColor,
                    () => _showAdjustStockDialog(product, provider),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildHistoryCard(StockHistoryModel history) {
    final isPositive = history.quantityChange > 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.productName ?? 'Product',
                  style: AppTheme.labelLarge,
                ),
                Text(
                  _getOperationLabel(history.operationType),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${history.quantityChange}',
                style: AppTheme.titleMedium.copyWith(color: color),
              ),
              Text(
                'New: ${history.quantityAfter}',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getOperationLabel(String type) {
    switch (type) {
      case AppConstants.stockIn:
        return 'Stock In';
      case AppConstants.stockOut:
        return 'Stock Out';
      case AppConstants.stockAdjust:
        return 'Adjustment';
      case AppConstants.stockSale:
        return 'Sale';
      case AppConstants.stockReturn:
        return 'Return';
      default:
        return type;
    }
  }

  Widget _buildEmptyState(String message) {
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
            message,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showStockInDialog(ProductModel product, ProductProvider provider) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTheme.titleMedium),
            Text(
              'Current Stock: ${product.quantity}',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: qtyController,
              label: 'Quantity to Add',
              hint: 'Enter quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: notesController,
              label: 'Notes (Optional)',
              hint: 'Enter notes',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text);
              if (qty != null && qty > 0) {
                final success = await provider.updateStock(
                  productId: product.id,
                  quantity: qty,
                  operationType: AppConstants.stockIn,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Stock updated' : 'Update failed'),
                    ),
                  );
                }
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  void _showStockOutDialog(ProductModel product, ProductProvider provider) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTheme.titleMedium),
            Text(
              'Current Stock: ${product.quantity}',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: qtyController,
              label: 'Quantity to Remove',
              hint: 'Enter quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: notesController,
              label: 'Reason (Optional)',
              hint: 'Enter reason',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              final qty = int.tryParse(qtyController.text);
              if (qty != null && qty > 0) {
                final success = await provider.updateStock(
                  productId: product.id,
                  quantity: qty,
                  operationType: AppConstants.stockOut,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Stock updated' : 'Update failed'),
                    ),
                  );
                }
              }
            },
            child: const Text('Remove Stock'),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(ProductModel product, ProductProvider provider) {
    final qtyController =
        TextEditingController(text: product.quantity.toString());
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTheme.titleMedium),
            Text(
              'Current Stock: ${product.quantity}',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: qtyController,
              label: 'New Quantity',
              hint: 'Enter new quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: notesController,
              label: 'Reason for Adjustment',
              hint: 'Enter reason',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text);
              if (qty != null && qty >= 0) {
                final success = await provider.updateStock(
                  productId: product.id,
                  quantity: qty,
                  operationType: AppConstants.stockAdjust,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : 'Manual adjustment',
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Stock adjusted' : 'Adjustment failed'),
                    ),
                  );
                }
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }
}

