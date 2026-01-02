import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/pos_provider.dart';
import '../../widgets/common/custom_button.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

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
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Point of Sale',
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
          onPressed: () {
            context.read<POSProvider>().clearCart();
            Navigator.pop(context);
          },
        ),
        actions: [
          Consumer<POSProvider>(
            builder: (context, pos, _) {
              if (pos.cart.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => pos.clearCart(),
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                label: const Text(
                  'Clear',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
      body: isWideScreen
          ? _buildWideLayout()
          : _buildMobileLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Products Section
        Expanded(
          flex: 2,
          child: _buildProductsSection(),
        ),
        // Cart Section
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: _buildCartSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Products Section
        Expanded(child: _buildProductsSection()),
        // Cart Summary
        Consumer<POSProvider>(
          builder: (context, pos, _) {
            if (pos.cart.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${pos.totalItems} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PKR ${pos.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _showCartBottomSheet(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name, SKU or ...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade500),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor, size: 20),
                          onPressed: () {
                            // TODO: Implement barcode scanner
                          },
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        // Category Filter
        Consumer<ProductProvider>(
          builder: (context, provider, _) {
            return SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = provider.selectedCategoryId == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => provider.setSelectedCategory(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected) const Icon(Icons.check, size: 16, color: Colors.white),
                              if (isSelected) const SizedBox(width: 4),
                              Text(
                                'All',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final category = provider.categories[index - 1];
                  final isSelected = provider.selectedCategoryId == category.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => provider.setSelectedCategory(category.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Products Grid
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final products = _getFilteredProducts(provider);

              if (products.isEmpty) {
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
                        'No products found',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(products[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<ProductModel> _getFilteredProducts(ProductProvider provider) {
    var products = provider.products.where((p) => p.isActive).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      products = products.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          (p.barcode?.toLowerCase().contains(query) ?? false)).toList();
    }

    return products;
  }

  Widget _buildProductCard(ProductModel product) {
    final posProvider = context.read<POSProvider>();
    final cartItem = posProvider.cart.cast<CartItem?>().firstWhere(
          (item) => item?.product.id == product.id,
          orElse: () => null,
        );
    final isInCart = cartItem != null;

    return GestureDetector(
      onTap: product.isOutOfStock
          ? null
          : () => posProvider.addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCart ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isInCart ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isInCart 
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : Colors.grey.shade100,
                      ),
                      child: _buildPosProductImage(
                        product.imageUrl,
                        product.isOutOfStock,
                        isInCart,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Product Name
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: product.isOutOfStock
                            ? Colors.grey.shade400
                            : Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Price
                  Text(
                    'PKR ${product.salePrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: product.isOutOfStock
                          ? Colors.grey.shade400
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stock
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stock: ${product.quantity}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: product.isLowStock
                            ? Colors.orange.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cart Quantity Badge
            if (isInCart)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            // Out of Stock Badge
            if (product.isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to build product image with network or file support for POS
  Widget _buildPosProductImage(String? imageUrl, bool isOutOfStock, bool isInCart) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(
        Icons.phone_android,
        color: isOutOfStock
            ? Colors.grey.shade400
            : isInCart 
                ? AppTheme.primaryColor
                : Colors.grey.shade600,
        size: 28,
      );
    }

    Widget imageWidget;

    // Check if it's a network URL or local file
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.phone_android,
            color: isOutOfStock
                ? Colors.grey.shade400
                : isInCart 
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
            size: 28,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          );
        },
      );
    } else {
      // Local file
      imageWidget = Image.file(
        File(imageUrl),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.phone_android,
            color: isOutOfStock
                ? Colors.grey.shade400
                : isInCart 
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
            size: 28,
          );
        },
      );
    }

    // Apply grayscale filter if out of stock
    if (isOutOfStock) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildCartSection() {
    return Consumer<POSProvider>(
      builder: (context, pos, _) {
        return Column(
          children: [
            // Cart Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text('Cart', style: AppTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '${pos.totalItems} items',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Customer Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCustomerSelector(pos),
            ),

            // Cart Items
            Expanded(
              child: pos.cart.isEmpty
                  ? Center(
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
                            'Cart is empty',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pos.cart.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(pos.cart[index], pos);
                      },
                    ),
            ),

            // Cart Summary & Checkout
            if (pos.cart.isNotEmpty) _buildCartSummary(pos),
          ],
        );
      },
    );
  }

  Widget _buildCustomerSelector(POSProvider pos) {
    return GestureDetector(
      onTap: () => _showCustomerSelector(pos),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pos.selectedCustomer?.name ?? 'Walk-in Customer',
                    style: AppTheme.labelLarge,
                  ),
                  if (pos.selectedCustomer != null &&
                      pos.selectedCustomer!.hasOutstanding)
                    Text(
                      'Outstanding: PKR ${pos.selectedCustomer!.outstandingBalance.toStringAsFixed(0)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.warningColor,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, POSProvider pos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: AppTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showPriceEditor(item, pos),
                      child: Text(
                        'PKR ${item.unitPrice.toStringAsFixed(0)} each',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                onPressed: () => pos.removeFromCart(item.product.id),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () => pos.decrementQuantity(item.product.id),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}',
                        style: AppTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => pos.incrementQuantity(item.product.id),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'PKR ${item.totalPrice.toStringAsFixed(0)}',
                style: AppTheme.priceText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(POSProvider pos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Discount & Tax
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showDiscountDialog(pos),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.discount_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            pos.calculatedDiscount > 0
                                ? '-${pos.calculatedDiscount.toStringAsFixed(0)}'
                                : 'Discount',
                            style: AppTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTaxDialog(pos),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            pos.taxAmount > 0
                                ? '+${pos.taxAmount.toStringAsFixed(0)}'
                                : 'Tax',
                            style: AppTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Lines
            _buildSummaryLine('Subtotal', pos.subtotal),
            if (pos.calculatedDiscount > 0)
              _buildSummaryLine('Discount', -pos.calculatedDiscount,
                  color: AppTheme.successColor),
            if (pos.taxAmount > 0)
              _buildSummaryLine('Tax (${pos.taxPercent}%)', pos.taxAmount),
            const Divider(height: 16),
            _buildSummaryLine('Total', pos.totalAmount, isTotal: true),

            const SizedBox(height: 16),

            // Checkout Button
            CustomButton(
              text: 'Checkout - PKR ${pos.totalAmount.toStringAsFixed(0)}',
              onPressed: () => _showCheckoutDialog(pos),
              icon: Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String label, double amount,
      {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTheme.titleMedium : AppTheme.bodyMedium,
          ),
          Text(
            '${amount < 0 ? '-' : ''}PKR ${amount.abs().toStringAsFixed(0)}',
            style: isTotal
                ? AppTheme.priceLarge
                : AppTheme.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildCartSection(),
      ),
    );
  }

  void _showCustomerSelector(POSProvider pos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Consumer<CustomerProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Customer', style: AppTheme.headingSmall),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: const Text('Walk-in Customer'),
                  onTap: () {
                    pos.setCustomer(null);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.customers.length,
                    itemBuilder: (context, index) {
                      final customer = provider.customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(customer.name[0].toUpperCase()),
                        ),
                        title: Text(customer.name),
                        subtitle: customer.hasOutstanding
                            ? Text(
                                'Outstanding: PKR ${customer.outstandingBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppTheme.warningColor,
                                ),
                              )
                            : customer.phone != null
                                ? Text(customer.phone!)
                                : null,
                        onTap: () {
                          pos.setCustomer(customer);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPriceEditor(CartItem item, POSProvider pos) {
    final controller =
        TextEditingController(text: item.unitPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Unit Price',
            prefixText: 'PKR ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                pos.updateItemPrice(item.product.id, price);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(POSProvider pos) {
    final percentController =
        TextEditingController(text: pos.discountPercent.toString());
    final amountController =
        TextEditingController(text: pos.discountAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount Percentage',
                suffixText: '%',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  amountController.text = '0';
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('OR'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount Amount',
                prefixText: 'PKR ',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  percentController.text = '0';
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              pos.setDiscountPercent(0);
              pos.setDiscountAmount(0);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              final percent = double.tryParse(percentController.text) ?? 0;
              final amount = double.tryParse(amountController.text) ?? 0;

              if (amount > 0) {
                pos.setDiscountAmount(amount);
              } else if (percent > 0) {
                pos.setDiscountPercent(percent);
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog(POSProvider pos) {
    final controller =
        TextEditingController(text: pos.taxPercent.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Tax Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tax Percentage',
            suffixText: '%',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final percent = double.tryParse(controller.text) ?? 0;
              pos.setTaxPercent(percent);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(POSProvider pos) {
    final paidController =
        TextEditingController(text: pos.totalAmount.toStringAsFixed(0));
    String selectedMethod = pos.paymentMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment', style: AppTheme.headingSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount'),
                      Text(
                        'PKR ${pos.totalAmount.toStringAsFixed(0)}',
                        style: AppTheme.priceLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method
                Text('Payment Method', style: AppTheme.labelLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPaymentMethodChip(
                      'Cash',
                      AppConstants.paymentCash,
                      Icons.money,
                      selectedMethod,
                      (m) => setState(() {
                        selectedMethod = m;
                        pos.setPaymentMethod(m);
                      }),
                    ),
                    _buildPaymentMethodChip(
                      'Card',
                      AppConstants.paymentCard,
                      Icons.credit_card,
                      selectedMethod,
                      (m) => setState(() {
                        selectedMethod = m;
                        pos.setPaymentMethod(m);
                      }),
                    ),
                    _buildPaymentMethodChip(
                      'Credit',
                      AppConstants.paymentCredit,
                      Icons.account_balance_wallet,
                      selectedMethod,
                      (m) => setState(() {
                        selectedMethod = m;
                        pos.setPaymentMethod(m);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Paid Amount
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    prefixText: 'PKR ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    pos.setPaidAmount(double.tryParse(value) ?? 0);
                  },
                ),
                const SizedBox(height: 12),

                // Change/Due
                if (double.tryParse(paidController.text) != null)
                  Builder(
                    builder: (context) {
                      final paid = double.parse(paidController.text);
                      final change = paid - pos.totalAmount;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: change >= 0
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(change >= 0 ? 'Change' : 'Due'),
                            Text(
                              'PKR ${change.abs().toStringAsFixed(0)}',
                              style: AppTheme.titleMedium.copyWith(
                                color: change >= 0
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Complete Sale Button
                Consumer<POSProvider>(
                  builder: (context, posProvider, _) {
                    return CustomButton(
                      text: 'Complete Sale',
                      isLoading: posProvider.isProcessing,
                      onPressed: () async {
                        pos.setPaidAmount(
                            double.tryParse(paidController.text) ?? 0);

                        final productProvider = context.read<ProductProvider>();
                        final customerProvider =
                            context.read<CustomerProvider>();

                        final sale = await pos.processSale(
                          productProvider: productProvider,
                          customerProvider: customerProvider,
                        );

                        if (sale != null && mounted) {
                          Navigator.pop(context);
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Sale completed: ${sale.invoiceNumber}'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(
    String label,
    String value,
    IconData icon,
    String selected,
    Function(String) onSelect,
  ) {
    final isSelected = selected == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
    );
  }
}

