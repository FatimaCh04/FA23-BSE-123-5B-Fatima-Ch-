import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_text_field.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxNameController = TextEditingController();
  final _taxRateController = TextEditingController();
  
  List<Map<String, dynamic>> _taxes = [];
  double _defaultTaxRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTaxes();
  }

  @override
  void dispose() {
    _taxNameController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _loadTaxes() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultTaxRate = prefs.getDouble(AppConstants.taxRateKey) ?? 0.0;
    
    // Load saved taxes from shared preferences
    final taxesJson = prefs.getStringList('saved_taxes') ?? [];
    _taxes = taxesJson.map((tax) {
      final parts = tax.split('|');
      return {
        'id': parts[0],
        'name': parts[1],
        'rate': double.parse(parts[2]),
        'isDefault': parts[3] == 'true',
        'isActive': parts[4] == 'true',
      };
    }).toList();
    
    // Add default tax if not exists
    if (_taxes.isEmpty) {
      _taxes = [
        {
          'id': '1',
          'name': 'Standard Tax',
          'rate': _defaultTaxRate,
          'isDefault': true,
          'isActive': true,
        },
      ];
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveTaxes() async {
    final prefs = await SharedPreferences.getInstance();
    final taxesJson = _taxes.map((tax) {
      return '${tax['id']}|${tax['name']}|${tax['rate']}|${tax['isDefault']}|${tax['isActive']}';
    }).toList();
    await prefs.setStringList('saved_taxes', taxesJson);
    
    // Update default tax rate
    final defaultTax = _taxes.firstWhere(
      (t) => t['isDefault'] == true,
      orElse: () => {'rate': 0.0},
    );
    await prefs.setDouble(AppConstants.taxRateKey, defaultTax['rate']);
  }

  void _showAddTaxDialog() {
    _taxNameController.clear();
    _taxRateController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_offer, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Add Tax', style: AppTheme.headingSmall),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _taxNameController,
                label: 'Tax Name',
                hint: 'e.g., GST, Sales Tax',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tax name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _taxRateController,
                label: 'Tax Rate (%)',
                hint: 'e.g., 16',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tax rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate < 0 || rate > 100) {
                    return 'Please enter valid rate (0-100)';
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
                _addTax();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTax() {
    setState(() {
      _taxes.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _taxNameController.text,
        'rate': double.parse(_taxRateController.text),
        'isDefault': _taxes.isEmpty,
        'isActive': true,
      });
    });
    _saveTaxes();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax added successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _setDefaultTax(String id) {
    setState(() {
      for (var tax in _taxes) {
        tax['isDefault'] = tax['id'] == id;
      }
    });
    _saveTaxes();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default tax updated'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _toggleTaxStatus(String id) {
    setState(() {
      final tax = _taxes.firstWhere((t) => t['id'] == id);
      tax['isActive'] = !tax['isActive'];
    });
    _saveTaxes();
  }

  void _deleteTax(String id) {
    final tax = _taxes.firstWhere((t) => t['id'] == id);
    if (tax['isDefault'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete default tax'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tax'),
        content: Text('Are you sure you want to delete "${tax['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _taxes.removeWhere((t) => t['id'] == id);
              });
              _saveTaxes();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tax deleted'),
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
        title: Text('Tax Management', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 7),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaxDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Tax'),
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
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.infoColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Default tax will be automatically applied to all new sales',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.infoColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tax List
                Expanded(
                  child: _taxes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _taxes.length,
                          itemBuilder: (context, index) {
                            return _buildTaxCard(_taxes[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTaxCard(Map<String, dynamic> tax) {
    final isDefault = tax['isDefault'] == true;
    final isActive = tax['isActive'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault 
              ? AppTheme.primaryColor.withOpacity(0.5)
              : AppTheme.dividerColor,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.textLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${tax['rate'].toStringAsFixed(0)}%',
                  style: AppTheme.titleMedium.copyWith(
                    color: isActive ? AppTheme.primaryColor : AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  tax['name'],
                  style: AppTheme.titleMedium.copyWith(
                    color: isActive ? AppTheme.textPrimary : AppTheme.textLight,
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              isActive ? 'Active' : 'Inactive',
              style: AppTheme.bodySmall.copyWith(
                color: isActive ? AppTheme.successColor : AppTheme.textLight,
              ),
            ),
            trailing: Switch(
              value: isActive,
              onChanged: (value) => _toggleTaxStatus(tax['id']),
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefaultTax(tax['id']),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Set Default'),
                  ),
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () => _deleteTax(tax['id']),
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
            Icons.local_offer_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No taxes configured',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a tax to apply to your sales',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

