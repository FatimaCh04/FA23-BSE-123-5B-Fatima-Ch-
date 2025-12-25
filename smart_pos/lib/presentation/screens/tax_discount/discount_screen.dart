import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_text_field.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountNameController = TextEditingController();
  final _discountValueController = TextEditingController();
  
  List<Map<String, dynamic>> _discounts = [];
  String _discountType = 'percentage'; // percentage or fixed
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  @override
  void dispose() {
    _discountNameController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscounts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved discounts from shared preferences
    final discountsJson = prefs.getStringList('saved_discounts') ?? [];
    _discounts = discountsJson.map((discount) {
      final parts = discount.split('|');
      return {
        'id': parts[0],
        'name': parts[1],
        'value': double.parse(parts[2]),
        'type': parts[3],
        'isActive': parts[4] == 'true',
      };
    }).toList();
    
    // Add default discounts if empty
    if (_discounts.isEmpty) {
      _discounts = [
        {
          'id': '1',
          'name': '5% Off',
          'value': 5.0,
          'type': 'percentage',
          'isActive': true,
        },
        {
          'id': '2',
          'name': '10% Off',
          'value': 10.0,
          'type': 'percentage',
          'isActive': true,
        },
        {
          'id': '3',
          'name': 'PKR 100 Off',
          'value': 100.0,
          'type': 'fixed',
          'isActive': true,
        },
      ];
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveDiscounts() async {
    final prefs = await SharedPreferences.getInstance();
    final discountsJson = _discounts.map((discount) {
      return '${discount['id']}|${discount['name']}|${discount['value']}|${discount['type']}|${discount['isActive']}';
    }).toList();
    await prefs.setStringList('saved_discounts', discountsJson);
  }

  void _showAddDiscountDialog() {
    _discountNameController.clear();
    _discountValueController.clear();
    _discountType = 'percentage';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.discount, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text('Add Discount', style: AppTheme.headingSmall),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _discountNameController,
                  label: 'Discount Name',
                  hint: 'e.g., Holiday Sale',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter discount name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Discount Type Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeOption(
                        'Percentage',
                        '%',
                        _discountType == 'percentage',
                        () => setDialogState(() => _discountType = 'percentage'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeOption(
                        'Fixed Amount',
                        'PKR',
                        _discountType == 'fixed',
                        () => setDialogState(() => _discountType = 'fixed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _discountValueController,
                  label: _discountType == 'percentage' 
                      ? 'Discount Percentage' 
                      : 'Discount Amount',
                  hint: _discountType == 'percentage' ? 'e.g., 10' : 'e.g., 100',
                  keyboardType: TextInputType.number,
                  suffix: Text(
                    _discountType == 'percentage' ? '%' : 'PKR',
                    style: AppTheme.bodyMedium,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter discount value';
                    }
                    final val = double.tryParse(value);
                    if (val == null || val <= 0) {
                      return 'Please enter valid value';
                    }
                    if (_discountType == 'percentage' && val > 100) {
                      return 'Percentage cannot exceed 100';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _addDiscount();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, String symbol, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: AppTheme.titleLarge.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDiscount() {
    final value = double.parse(_discountValueController.text);
    final name = _discountNameController.text.isNotEmpty
        ? _discountNameController.text
        : _discountType == 'percentage' 
            ? '${value.toStringAsFixed(0)}% Off'
            : 'PKR ${value.toStringAsFixed(0)} Off';
    
    setState(() {
      _discounts.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'value': value,
        'type': _discountType,
        'isActive': true,
      });
    });
    _saveDiscounts();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discount added successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _toggleDiscountStatus(String id) {
    setState(() {
      final discount = _discounts.firstWhere((d) => d['id'] == id);
      discount['isActive'] = !discount['isActive'];
    });
    _saveDiscounts();
  }

  void _deleteDiscount(String id) {
    final discount = _discounts.firstWhere((d) => d['id'] == id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discount'),
        content: Text('Are you sure you want to delete "${discount['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _discounts.removeWhere((d) => d['id'] == id);
              });
              _saveDiscounts();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Discount deleted'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discount Management', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDiscountDialog,
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Discount'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.discount, color: AppTheme.accentColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Quick discounts can be applied at checkout',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.accentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Discount List
                Expanded(
                  child: _discounts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _discounts.length,
                          itemBuilder: (context, index) {
                            return _buildDiscountCard(_discounts[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDiscountCard(Map<String, dynamic> discount) {
    final isActive = discount['isActive'] == true;
    final isPercentage = discount['type'] == 'percentage';
    final value = discount['value'] as double;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? AppTheme.accentColor.withOpacity(0.3)
              : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.accentColor.withOpacity(0.1)
                    : AppTheme.textLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPercentage ? '${value.toStringAsFixed(0)}%' : 'PKR',
                      style: AppTheme.titleMedium.copyWith(
                        color: isActive ? AppTheme.accentColor : AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: isPercentage ? 16 : 12,
                      ),
                    ),
                    if (!isPercentage)
                      Text(
                        value.toStringAsFixed(0),
                        style: AppTheme.labelLarge.copyWith(
                          color: isActive ? AppTheme.accentColor : AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            title: Text(
              discount['name'],
              style: AppTheme.titleMedium.copyWith(
                color: isActive ? AppTheme.textPrimary : AppTheme.textLight,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPercentage 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPercentage ? 'Percentage' : 'Fixed',
                    style: AppTheme.labelSmall.copyWith(
                      color: isPercentage 
                          ? AppTheme.primaryColor 
                          : AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: AppTheme.bodySmall.copyWith(
                    color: isActive ? AppTheme.successColor : AppTheme.textLight,
                  ),
                ),
              ],
            ),
            trailing: Switch(
              value: isActive,
              onChanged: (value) => _toggleDiscountStatus(discount['id']),
              activeColor: AppTheme.accentColor,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteDiscount(discount['id']),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
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
            Icons.discount_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No discounts configured',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add discounts for quick checkout',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

