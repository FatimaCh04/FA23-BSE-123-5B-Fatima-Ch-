import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: Color(0xFF8B5CF6), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Products',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildCategoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddProductDialog();
          } else {
            _showAddCategoryDialog();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Product' : 'Add Category',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search and Filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) => provider.setSearchQuery(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: provider.selectedCategoryId != null
                            ? AppTheme.primaryColor
                            : const Color(0xFF64748B),
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'all') {
                        provider.setSelectedCategory(null);
                      } else {
                        provider.setSelectedCategory(value);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Categories'),
                      ),
                      ...provider.categories.map(
                            (cat) => PopupMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildMiniStat(
                    'Total',
                    '${provider.totalProducts}',
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildMiniStat(
                    'Low Stock',
                    '${provider.lowStockCount}',
                    AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  _buildMiniStat(
                    'Out of Stock',
                    '${provider.outOfStockCount}',
                    AppTheme.errorColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Products List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.products.isEmpty
                  ? _buildEmptyState('No products found')
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.products.length,
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return _buildProductCard(product, provider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.categories.isEmpty) {
          return _buildEmptyState('No categories found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.categories.length,
          itemBuilder: (context, index) {
            final category = provider.categories[index];
            return _buildCategoryCard(category, provider);
          },
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTheme.titleMedium.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, ProductProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
            width: 60,
            height: 60,
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: _buildProductImage(product.imageUrl),
            ),
          ),
          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: AppTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.isLowStock && !product.isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Low Stock',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.warningColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (product.isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.errorColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.sku} • ${product.categoryName ?? "Uncategorized"}',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'PKR ${product.salePrice.toStringAsFixed(0)}',
                      style: AppTheme.priceText,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Qty: ${product.quantity}',
                        style: AppTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditProductDialog(product);
              } else if (value == 'delete') {
                _showDeleteConfirmation(
                  'Delete Product',
                  'Are you sure you want to delete ${product.name}?',
                      () => provider.deleteProduct(product.id),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper to build product/category image with network or file support
  Widget _buildProductImage(String? imageUrl, {double size = 60}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(
        Icons.inventory_2,
        color: AppTheme.primaryColor,
        size: size * 0.5,
      );
    }

    // Check if it's a network URL or local file
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.inventory_2,
            color: AppTheme.primaryColor,
            size: size * 0.5,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.3,
              height: size * 0.3,
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
      return Image.file(
        File(imageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.inventory_2,
            color: AppTheme.primaryColor,
            size: size * 0.5,
          );
        },
      );
    }
  }

  Widget _buildCategoryImage(String? imageUrl, String? iconName, {double size = 48}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildCategoryIcon(iconName, size);
            },
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imageUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildCategoryIcon(iconName, size);
            },
          ),
        );
      }
    }
    return _buildCategoryIcon(iconName, size);
  }

  Widget _buildCategoryIcon(String? iconName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIcon(iconName),
        color: AppTheme.primaryColor,
        size: size * 0.5,
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'phone_android':
        return Icons.phone_android;
      case 'tablet_android':
        return Icons.tablet_android;
      case 'laptop':
        return Icons.laptop;
      case 'headphones':
        return Icons.headphones;
      case 'cable':
        return Icons.cable;
      case 'smartphone':
        return Icons.smartphone;
      case 'headset':
        return Icons.headset;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'watch':
        return Icons.watch;
      case 'build':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategoryCard(CategoryModel category, ProductProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          _buildCategoryImage(category.imageUrl, category.iconName),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: AppTheme.titleMedium),
                if (category.description != null)
                  Text(
                    category.description!,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditCategoryDialog(category);
              } else if (value == 'delete') {
                _showCategoryDeleteDialog(category, provider);
              }
            },
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

  // ======== ADD / EDIT PRODUCT ========
  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final descriptionController = TextEditingController();
    final costController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final taxController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '10');
    final barcodeController = TextEditingController();
    String? selectedCategoryId;
    String? imagePath;
    bool hasDiscount = false;
    bool hasTax = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header with drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text('Create Product', style: AppTheme.headingSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          // Product Name
                        CustomTextField(
                          controller: nameController,
                          label: 'Product Name',
                          hint: 'Enter product name',
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                          
                          // SKU
                        CustomTextField(
                          controller: skuController,
                          label: 'SKU',
                          hint: 'Enter SKU code',
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                          
                          // Category Dropdown
                        Consumer<ProductProvider>(
                          builder: (context, provider, _) {
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: provider.categories
                                  .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                                  .toList(),
                              onChanged: (v) => selectedCategoryId = v,
                              validator: (v) => v == null ? 'Required' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                          // Description (Optional)
                          CustomTextField(
                            controller: descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Enter product description',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Quantity and Unit
                        Row(
                          children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: qtyController,
                                  label: 'Quantity',
                                  hint: 'Quantity',
                                  keyboardType: TextInputType.number,
                                ),
                            ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: unitController,
                                  label: 'Unit',
                                  hint: 'Unit',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                          // Purchase Price and Sale Price
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: costController,
                                  label: 'Purchase Price',
                                  hint: 'Purchase Price',
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: priceController,
                                label: 'Sale Price',
                                  hint: 'Sale Price',
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                          // Discount and Tax Toggles
                        Row(
                          children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch(
                                      value: hasDiscount,
                                      onChanged: (v) => setModalState(() => hasDiscount = v),
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const Text('Discount'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch(
                                      value: hasTax,
                                      onChanged: (v) => setModalState(() => hasTax = v),
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const Text('Tax'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Discount and Tax Fields (shown when enabled)
                          if (hasDiscount || hasTax) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (hasDiscount)
                            Expanded(
                              child: CustomTextField(
                                      controller: discountController,
                                      label: 'Discount %',
                                hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                                if (hasDiscount && hasTax) const SizedBox(width: 16),
                                if (hasTax)
                            Expanded(
                              child: CustomTextField(
                                      controller: taxController,
                                      label: 'Tax %',
                                      hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                          ],
                        const SizedBox(height: 16),

                          // Low Stock Alert
                          CustomTextField(
                            controller: thresholdController,
                            label: 'Low Stock Alert',
                            hint: '10',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Barcode
                        CustomTextField(
                          controller: barcodeController,
                          label: 'Barcode (Optional)',
                          hint: 'Scan or enter barcode',
                        ),
                          const SizedBox(height: 16),

                          // Image Picker - Camera and Gallery options
                          Text('Product Image', style: AppTheme.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80,
                                    );
                                    if (picked != null) {
                                      setModalState(() => imagePath = picked.path);
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (picked != null) {
                                      setModalState(() => imagePath = picked.path);
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surfaceColor,
                                    foregroundColor: AppTheme.textPrimary,
                                    side: const BorderSide(color: AppTheme.dividerColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (imagePath != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Image selected',
                                    style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setModalState(() => imagePath = null),
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                    text: 'Create Product',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<ProductProvider>();
                      final product = ProductModel(
                        id: '',
                        sku: skuController.text,
                        name: nameController.text,
                          description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                        categoryId: selectedCategoryId!,
                          costPrice: double.tryParse(costController.text) ?? 0,
                          salePrice: double.tryParse(priceController.text) ?? 0,
                        quantity: int.tryParse(qtyController.text) ?? 0,
                          unit: unitController.text.isNotEmpty ? unitController.text : null,
                          discount: double.tryParse(discountController.text) ?? 0,
                          tax: double.tryParse(taxController.text) ?? 0,
                          hasDiscount: hasDiscount,
                          hasTax: hasTax,
                        lowStockThreshold: int.tryParse(thresholdController.text) ?? 10,
                        barcode: barcodeController.text.isNotEmpty ? barcodeController.text : null,
                        imageUrl: imagePath,
                        createdAt: DateTime.now(),
                      );

                      final success = await provider.addProduct(product);
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Product added'), backgroundColor: AppTheme.snackBarAdd),
                        );
                      }
                    }
                  },
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== ADD CATEGORY =====
  void _showAddCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: formKey,
            child: SingleChildScrollView(
          child: Column(
                mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Category', style: AppTheme.headingSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: nameController,
                label: 'Category Name',
                hint: 'Enter category name',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: descController,
                label: 'Description (Optional)',
                hint: 'Enter description',
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Add Category',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final provider = context.read<ProductProvider>();
                    final category = CategoryModel(
                      id: '',
                      name: nameController.text,
                      description: descController.text.isNotEmpty ? descController.text : null,
                      createdAt: DateTime.now(),
                    );
                    final success = await provider.addCategory(category);
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Category added'), backgroundColor: AppTheme.snackBarAdd),
                      );
                    }
                  }
                },
              ),
                  const SizedBox(height: 16),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== EDIT CATEGORY =====
  void _showEditCategoryDialog(CategoryModel category) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(text: category.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: formKey,
            child: SingleChildScrollView(
          child: Column(
                mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Category', style: AppTheme.headingSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: nameController,
                label: 'Category Name',
                hint: 'Enter category name',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: descController,
                label: 'Description (Optional)',
                hint: 'Enter description',
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Update Category',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final provider = context.read<ProductProvider>();
                    final updated = category.copyWith(
                      name: nameController.text,
                      description: descController.text.isNotEmpty ? descController.text : null,
                      updatedAt: DateTime.now(),
                    );
                    final success = await provider.updateCategory(updated);
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Category updated'), backgroundColor: AppTheme.snackBarUpdate),
                      );
                    }
                  }
                },
              ),
                  const SizedBox(height: 16),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== EDIT PRODUCT =====
  void _showEditProductDialog(ProductModel product) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku);
    final descriptionController = TextEditingController(text: product.description ?? '');
    final costController = TextEditingController(text: product.costPrice.toString());
    final priceController = TextEditingController(text: product.salePrice.toString());
    final qtyController = TextEditingController(text: product.quantity.toString());
    final unitController = TextEditingController(text: product.unit ?? '');
    final discountController = TextEditingController(text: product.discount.toString());
    final taxController = TextEditingController(text: product.tax.toString());
    final thresholdController = TextEditingController(text: product.lowStockThreshold.toString());
    final barcodeController = TextEditingController(text: product.barcode ?? '');
    
    // Get provider to check if category exists
    final provider = context.read<ProductProvider>();
    final categoryExists = provider.categories.any((c) => c.id == product.categoryId);
    String? selectedCategoryId = categoryExists ? product.categoryId : null;
    String? imagePath = product.imageUrl;
    bool hasDiscount = product.hasDiscount;
    bool hasTax = product.hasTax;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header with drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Product', style: AppTheme.headingSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          // Product Name
                        CustomTextField(
                          controller: nameController,
                          label: 'Product Name',
                          hint: 'Enter product name',
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                          
                          // SKU
                        CustomTextField(
                          controller: skuController,
                          label: 'SKU',
                            hint: 'Enter SKU code',
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                          
                          // Category Dropdown
                        Consumer<ProductProvider>(
                          builder: (context, provider, _) {
                              // Verify the selected category still exists in the list
                              final validCategoryId = provider.categories.any((c) => c.id == selectedCategoryId)
                                  ? selectedCategoryId
                                  : null;
                              
                            return DropdownButtonFormField<String>(
                                value: validCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: provider.categories
                                  .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                                  .toList(),
                              onChanged: (v) => selectedCategoryId = v,
                              validator: (v) => v == null ? 'Required' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                          // Description (Optional)
                          CustomTextField(
                            controller: descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Enter product description',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Quantity and Unit
                        Row(
                          children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: qtyController,
                                  label: 'Quantity',
                                  hint: 'Quantity',
                                  keyboardType: TextInputType.number,
                                ),
                            ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: unitController,
                                  label: 'Unit',
                                  hint: 'Unit',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                          // Purchase Price and Sale Price
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: costController,
                                  label: 'Purchase Price',
                                  hint: 'Purchase Price',
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: priceController,
                                label: 'Sale Price',
                                  hint: 'Sale Price',
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                          // Discount and Tax Toggles
                        Row(
                          children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch(
                                      value: hasDiscount,
                                      onChanged: (v) => setModalState(() => hasDiscount = v),
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const Text('Discount'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch(
                                      value: hasTax,
                                      onChanged: (v) => setModalState(() => hasTax = v),
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const Text('Tax'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Discount and Tax Fields (shown when enabled)
                          if (hasDiscount || hasTax) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (hasDiscount)
                            Expanded(
                              child: CustomTextField(
                                      controller: discountController,
                                      label: 'Discount %',
                                hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                                if (hasDiscount && hasTax) const SizedBox(width: 16),
                                if (hasTax)
                            Expanded(
                              child: CustomTextField(
                                      controller: taxController,
                                      label: 'Tax %',
                                      hint: '0',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                          ],
                        const SizedBox(height: 16),

                          // Low Stock Alert
                          CustomTextField(
                            controller: thresholdController,
                            label: 'Low Stock Alert',
                            hint: '10',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Barcode
                        CustomTextField(
                          controller: barcodeController,
                          label: 'Barcode (Optional)',
                          hint: 'Scan or enter barcode',
                        ),
                          const SizedBox(height: 16),

                          // Image Picker - Camera and Gallery options
                          Text('Product Image', style: AppTheme.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80,
                                    );
                                    if (picked != null) {
                                      setModalState(() => imagePath = picked.path);
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (picked != null) {
                                      setModalState(() => imagePath = picked.path);
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surfaceColor,
                                    foregroundColor: AppTheme.textPrimary,
                                    side: const BorderSide(color: AppTheme.dividerColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (imagePath != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Image selected',
                                    style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setModalState(() => imagePath = null),
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Update Product',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<ProductProvider>();
                      final updated = product.copyWith(
                        name: nameController.text,
                        sku: skuController.text,
                          description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                        categoryId: selectedCategoryId!,
                          costPrice: double.tryParse(costController.text) ?? 0,
                          salePrice: double.tryParse(priceController.text) ?? 0,
                        quantity: int.tryParse(qtyController.text) ?? 0,
                          unit: unitController.text.isNotEmpty ? unitController.text : null,
                          discount: double.tryParse(discountController.text) ?? 0,
                          tax: double.tryParse(taxController.text) ?? 0,
                          hasDiscount: hasDiscount,
                          hasTax: hasTax,
                        lowStockThreshold: int.tryParse(thresholdController.text) ?? 10,
                        barcode: barcodeController.text.isNotEmpty ? barcodeController.text : null,
                        imageUrl: imagePath,
                        updatedAt: DateTime.now(),
                      );

                      final success = await provider.updateProduct(updated);
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Product updated'), backgroundColor: AppTheme.snackBarUpdate),
                        );
                      }
                    }
                  },
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryDeleteDialog(CategoryModel category, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Category'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category.name}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Force Delete will also delete all products in this category',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              final success = await provider.deleteCategory(category.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Category deleted' : provider.errorMessage ?? 'Failed'),
                    backgroundColor: success ? AppTheme.snackBarDelete : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.deleteCategory(category.id, forceDelete: true);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Category & products deleted' : 'Failed'),
                    backgroundColor: success ? AppTheme.snackBarDelete : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Force Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String title, String message, Future<bool> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await onConfirm();
              Navigator.pop(context);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Deleted successfully'), backgroundColor: AppTheme.snackBarDelete),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
