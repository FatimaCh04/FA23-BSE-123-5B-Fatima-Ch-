import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/ledger_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedFilter = 'all';
  
  // Date filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilterLabel = 'All Time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Customers',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Color(0xFF2D3748)),
            tooltip: 'Filter by Date',
            onPressed: _showDateFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFF2D3748)),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
              context.read<CustomerProvider>().setCustomerTypeFilter(value);
            },
            itemBuilder: (context) => [
              _buildFilterMenuItem('all', 'All Customers'),
              _buildFilterMenuItem('regular', 'Regular Customers'),
              _buildFilterMenuItem('with_balance', 'With Balance'),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(text: 'All Customers', icon: Icon(Icons.people)),
            Tab(text: 'Top Customers', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllCustomersTab(provider),
              _buildTopCustomersTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _selectedFilter == value ? Icons.check_circle : Icons.circle_outlined,
            color: _selectedFilter == value ? AppTheme.primaryColor : AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.date_range,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filter by Date', style: AppTheme.headingSmall),
                            Text(
                              'Select date range',
                              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Quick Filter Buttons
                        _buildQuickDateButton(
                          'Today So Far',
                          () {
                            final now = DateTime.now();
                            setModalState(() {
                              tempStartDate = DateTime(now.year, now.month, now.day);
                              tempEndDate = now;
                            });
                          },
                          setModalState,
                        ),
                        const SizedBox(height: 8),
                        _buildQuickDateButton(
                          'This Week',
                          () {
                            final now = DateTime.now();
                            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                            setModalState(() {
                              tempStartDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                              tempEndDate = now;
                            });
                          },
                          setModalState,
                        ),
                        const SizedBox(height: 8),
                        _buildQuickDateButton(
                          'This Month',
                          () {
                            final now = DateTime.now();
                            setModalState(() {
                              tempStartDate = DateTime(now.year, now.month, 1);
                              tempEndDate = now;
                            });
                          },
                          setModalState,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Custom Date Range - Start Date
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => tempStartDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                tempStartDate != null
                                    ? DateFormat('dd/MM/yyyy').format(tempStartDate!)
                                    : 'Start Date',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // End Date
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => tempEndDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                tempEndDate != null
                                    ? DateFormat('dd/MM/yyyy').format(tempEndDate!)
                                    : 'End Date',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempStartDate = null;
                              tempEndDate = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _startDate = tempStartDate;
                              _endDate = tempEndDate;
                              if (_startDate != null && _endDate != null) {
                                _dateFilterLabel = '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}';
                              } else if (_startDate != null) {
                                _dateFilterLabel = 'From ${DateFormat('dd/MM').format(_startDate!)}';
                              } else if (_endDate != null) {
                                _dateFilterLabel = 'Until ${DateFormat('dd/MM').format(_endDate!)}';
                              } else {
                                _dateFilterLabel = 'All Time';
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onTap, StateSetter setModalState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAllCustomersTab(CustomerProvider provider) {
    // Apply date filter to customers
    List<CustomerModel> filteredCustomers = provider.filteredCustomers;
    if (_startDate != null || _endDate != null) {
      filteredCustomers = filteredCustomers.where((customer) {
        final customerDate = customer.createdAt;
        if (_startDate != null && customerDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && customerDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }
    
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                  ),
                  onChanged: (value) => provider.setSearchQuery(value),
                ),
              ),

        // Date Filter Chip
        if (_startDate != null || _endDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _dateFilterLabel,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _dateFilterLabel = 'All Time';
                      });
                    },
                    child: const Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ),
        
        if (_startDate != null || _endDate != null)
          const SizedBox(height: 8),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildMiniStat(
                      'Total',
                      '${provider.totalCustomers}',
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      'With Balance',
                      '${provider.customersWithOutstandingCount}',
                      AppTheme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      'Receivable',
                      'PKR ${provider.totalReceivables.toStringAsFixed(0)}',
                      AppTheme.errorColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customers List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredCustomers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return _buildCustomerCard(customer, provider);
                            },
                          ),
              ),
            ],
          );
  }

  Widget _buildTopCustomersTab(CustomerProvider provider) {
    final topCustomers = provider.getTopCustomers(limit: 10);
    
    return Column(
      children: [
        // Stats Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Top Customers by Purchases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Business: PKR ${provider.customerStatistics['total_purchases']?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // Top Customers List
        Expanded(
          child: topCustomers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = topCustomers[index];
                    return _buildTopCustomerCard(customer, index + 1, provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTopCustomerCard(CustomerModel customer, int rank, CustomerProvider provider) {
    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.looks_one;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.looks_two;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.looks_3;
        break;
      default:
        rankColor = const Color(0xFF64748B);
        rankIcon = Icons.circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCustomerDetails(customer, provider),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(rankIcon, color: rankColor, size: 28)
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                      ),
              ),
            ),
            ),
            const SizedBox(width: 14),

            // Customer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: PKR ${customer.totalPurchases.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Outstanding Badge
            if (customer.hasOutstanding)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PKR ${customer.outstandingBalance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, CustomerProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCustomerDetails(customer, provider),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
              child: Text(
                customer.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                ),
              ),
            ),
            ),
            const SizedBox(width: 14),

            // Customer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      if (customer.hasOutstanding)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PKR ${customer.outstandingBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (customer.phone != null)
                    Text(
                      customer.phone!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  Text(
                    'Total: PKR ${customer.totalPurchases.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'payment',
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 20, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Record Payment'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryColor),
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
                switch (value) {
                  case 'payment':
                    _showPaymentDialog(customer, provider);
                    break;
                  case 'edit':
                    _showEditCustomerDialog(customer, provider);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(customer, provider);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
            Icons.people_outline,
              size: 48,
              color: Color(0xFF10B981),
          ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No customers found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first customer to get started',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Customer', style: AppTheme.headingSmall),
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
                      children: [
                        CustomTextField(
                          controller: nameController,
                          label: 'Customer Name',
                          hint: 'Enter full name',
                          prefixIcon: Icons.person_outline,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: phoneController,
                          label: 'Phone Number',
                          hint: 'Enter phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: emailController,
                          label: 'Email (Optional)',
                          hint: 'Enter email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: addressController,
                          label: 'Address (Optional)',
                          hint: 'Enter address',
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Add Customer',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<CustomerProvider>();
                      final customer = CustomerModel(
                        id: '',
                        name: nameController.text,
                        phone: phoneController.text.isNotEmpty
                            ? phoneController.text
                            : null,
                        email: emailController.text.isNotEmpty
                            ? emailController.text
                            : null,
                        address: addressController.text.isNotEmpty
                            ? addressController.text
                            : null,
                        customerType: AppConstants.customerRegular,
                        createdAt: DateTime.now(),
                      );

                      final success = await provider.addCustomer(customer);
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Customer added'), backgroundColor: AppTheme.snackBarAdd),
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
    );
  }

  void _showEditCustomerDialog(
      CustomerModel customer, CustomerProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final emailController = TextEditingController(text: customer.email ?? '');
    final addressController =
        TextEditingController(text: customer.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Customer', style: AppTheme.headingSmall),
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
                      children: [
                        CustomTextField(
                          controller: nameController,
                          label: 'Customer Name',
                          hint: 'Enter full name',
                          prefixIcon: Icons.person_outline,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: phoneController,
                          label: 'Phone Number',
                          hint: 'Enter phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: emailController,
                          label: 'Email (Optional)',
                          hint: 'Enter email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: addressController,
                          label: 'Address (Optional)',
                          hint: 'Enter address',
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Update Customer',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final updated = customer.copyWith(
                        name: nameController.text,
                        phone: phoneController.text.isNotEmpty
                            ? phoneController.text
                            : null,
                        email: emailController.text.isNotEmpty
                            ? emailController.text
                            : null,
                        address: addressController.text.isNotEmpty
                            ? addressController.text
                            : null,
                      );

                      final success = await provider.updateCustomer(updated);
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Customer updated'), backgroundColor: AppTheme.snackBarUpdate),
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
    );
  }

  void _showPaymentDialog(CustomerModel customer, CustomerProvider provider) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.name, style: AppTheme.titleMedium),
            Text(
              'Outstanding: PKR ${customer.outstandingBalance.toStringAsFixed(0)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: amountController,
              label: 'Payment Amount',
              hint: 'Enter amount',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: notesController,
              label: 'Notes (Optional)',
              hint: 'Payment reference',
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
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final success = await provider.recordPayment(
                  customerId: customer.id,
                  amount: amount,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(success ? 'Payment recorded' : 'Payment failed'),
                    ),
                  );
                }
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(CustomerModel customer, CustomerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailsSheet(customer: customer, provider: provider),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      CustomerModel customer, CustomerProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await provider.deleteCustomer(customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Customer deleted' : provider.errorMessage ?? 'Delete failed',
            ),
          ),
        );
      }
    }
  }
}

// Customer Details Sheet with Tabs
class _CustomerDetailsSheet extends StatefulWidget {
  final CustomerModel customer;
  final CustomerProvider provider;

  const _CustomerDetailsSheet({
    required this.customer,
    required this.provider,
  });

  @override
  State<_CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load purchase history
    widget.provider.getCustomerPurchaseHistory(widget.customer.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
          // Header with Customer Info
          _buildHeader(),

          // Action Buttons
          _buildActionButtons(),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Purchases'),
              Tab(text: 'Ledger'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPurchasesTab(),
                _buildLedgerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Customer Profile',
                style: AppTheme.titleLarge.copyWith(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  // Trigger edit dialog
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
                  CircleAvatar(
                    backgroundColor: Colors.white,
            radius: 40,
                    child: Text(
              widget.customer.name[0].toUpperCase(),
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
            widget.customer.name,
                    style: AppTheme.headingSmall.copyWith(color: Colors.white),
                  ),
          if (widget.customer.phone != null)
                    Text(
              widget.customer.phone!,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.customer.customerType == AppConstants.customerRegular
                  ? 'Regular Customer'
                  : 'Walk-in Customer',
              style: AppTheme.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
            child: _buildActionButton(
              icon: Icons.payment,
              label: 'Receive Payment',
              color: AppTheme.successColor,
              onTap: () => _showPaymentDialog(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_circle_outline,
              label: 'Add Debit',
              color: AppTheme.warningColor,
              onTap: () => _showDebitDialog(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.receipt_long,
              label: 'Statement',
              color: AppTheme.primaryColor,
              onTap: () => _showStatementDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                      'Total Purchases',
                  'PKR ${widget.customer.totalPurchases.toStringAsFixed(0)}',
                  Icons.shopping_cart,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                child: _buildStatCard(
                  'Total Paid',
                  'PKR ${widget.customer.totalPayments.toStringAsFixed(0)}',
                  Icons.payments,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                      'Outstanding',
                  'PKR ${widget.customer.outstandingBalance.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  widget.customer.hasOutstanding
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Last Purchase',
                  widget.customer.lastPurchaseDate != null
                      ? dateFormat.format(widget.customer.lastPurchaseDate!)
                      : 'N/A',
                  Icons.calendar_today,
                  AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 24),

          // Contact Information
          Text('Contact Information', style: AppTheme.titleLarge),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Phone', widget.customer.phone ?? 'Not provided'),
          _buildInfoRow(Icons.email, 'Email', widget.customer.email ?? 'Not provided'),
          _buildInfoRow(Icons.location_on, 'Address', widget.customer.address ?? 'Not provided'),

          const SizedBox(height: 24),

          // Account Details
          Text('Account Details', style: AppTheme.titleLarge),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.badge, 'Customer ID', widget.customer.id.substring(0, 8)),
          _buildInfoRow(Icons.category, 'Type', 
              widget.customer.customerType == AppConstants.customerRegular ? 'Regular' : 'Walk-in'),
          _buildInfoRow(Icons.event, 'Member Since', dateFormat.format(widget.customer.createdAt)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.labelSmall),
              Text(value, style: AppTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final purchases = provider.customerPurchaseHistory;

        if (purchases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No purchase history',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final sale = purchases[index];
            return _buildPurchaseCard(sale);
          },
        );
      },
    );
  }

  Widget _buildPurchaseCard(SaleModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt, color: AppTheme.primaryColor),
        ),
        title: Text(sale.invoiceNumber, style: AppTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(sale.saleDate),
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'PKR ${sale.totalAmount.toStringAsFixed(0)}',
                  style: AppTheme.priceText,
                ),
                const SizedBox(width: 8),
                if (sale.dueAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Due: PKR ${sale.dueAmount.toStringAsFixed(0)}',
                      style: AppTheme.labelSmall.copyWith(color: AppTheme.warningColor),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Paid',
                      style: AppTheme.labelSmall.copyWith(color: AppTheme.successColor),
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          // Sale Items
          ...sale.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
            Expanded(
                      child: Text(
                        '${item.productName} x${item.quantity}',
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      'PKR ${item.totalPrice.toStringAsFixed(0)}',
                      style: AppTheme.labelLarge,
                    ),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTheme.bodyMedium),
              Text('PKR ${sale.subtotal.toStringAsFixed(0)}'),
            ],
          ),
          if (sale.discountAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount', style: AppTheme.bodyMedium),
                Text('-PKR ${sale.discountAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.successColor)),
              ],
            ),
          if (sale.taxAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax', style: AppTheme.bodyMedium),
                Text('PKR ${sale.taxAmount.toStringAsFixed(0)}'),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTheme.titleMedium),
              Text('PKR ${sale.totalAmount.toStringAsFixed(0)}', style: AppTheme.priceText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab() {
    return FutureBuilder(
      future: widget.provider.getCustomerLedger(widget.customer.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No ledger entries',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                ),
              ],
                      ),
                    );
                  }

                  final ledger = snapshot.data!;
        return Column(
          children: [
            // Ledger Summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${ledger.length}',
                          style: AppTheme.titleLarge.copyWith(color: AppTheme.primaryColor),
                        ),
                        Text('Transactions', style: AppTheme.labelSmall),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppTheme.dividerColor),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'PKR ${widget.customer.outstandingBalance.toStringAsFixed(0)}',
                          style: AppTheme.titleLarge.copyWith(
                            color: widget.customer.hasOutstanding
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                          ),
                        ),
                        Text('Balance', style: AppTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ledger List
            Expanded(
              child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ledger.length,
                    itemBuilder: (context, index) {
                      final entry = ledger[index];
                      final isPayment = entry.isPayment;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPayment
                                    ? AppTheme.successColor.withOpacity(0.1)
                                    : AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                            isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isPayment ? AppTheme.successColor : AppTheme.errorColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(entry.description, style: AppTheme.labelLarge),
                                  Text(
                                dateFormat.format(entry.transactionDate),
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isPayment ? '-' : '+'}PKR ${entry.amount.toStringAsFixed(0)}',
                              style: AppTheme.titleMedium.copyWith(
                                color: isPayment ? AppTheme.successColor : AppTheme.errorColor,
                              ),
                            ),
                            Text(
                              'Bal: PKR ${entry.balanceAfter.toStringAsFixed(0)}',
                              style: AppTheme.labelSmall,
                            ),
                          ],
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

  void _showPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Receive Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customer.name, style: AppTheme.titleMedium),
            Text(
              'Outstanding: PKR ${widget.customer.outstandingBalance.toStringAsFixed(0)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'PKR ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final success = await widget.provider.recordPayment(
                  customerId: widget.customer.id,
                  amount: amount,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Payment recorded' : 'Payment failed')),
                  );
                  if (success) {
                    setState(() {});
                  }
                }
              }
            },
            child: const Text('Receive'),
          ),
        ],
      ),
    );
  }

  void _showDebitDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Debit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(widget.customer.name, style: AppTheme.titleMedium),
          Text(
              'Current Balance: PKR ${widget.customer.outstandingBalance.toStringAsFixed(0)}',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'PKR ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Opening balance, Adjustment',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
          ),
        ],
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final description = descriptionController.text.trim();
              if (amount != null && amount > 0 && description.isNotEmpty) {
                final success = await widget.provider.addDebit(
                  customerId: widget.customer.id,
                  amount: amount,
                  description: description,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Debit added' : 'Failed to add debit')),
                  );
                  if (success) {
                    setState(() {});
                  }
                }
              }
            },
            child: const Text('Add Debit'),
          ),
        ],
      ),
    );
  }

  void _showStatementDialog() {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Statement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(startDate != null ? dateFormat.format(startDate!) : 'Select'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(endDate != null ? dateFormat.format(endDate!) : 'Select'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => endDate = date);
                  }
                },
              ),
            ],
          ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showStatementPreview(startDate, endDate);
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatementPreview(DateTime? startDate, DateTime? endDate) async {
    final statement = await widget.provider.getCustomerStatement(
      widget.customer.id,
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    // Get ledger entries for PDF
    final ledgerEntries = statement.map((e) => e['ledger'] as LedgerModel).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer Statement', style: AppTheme.titleLarge),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.print, color: AppTheme.primaryColor),
                            onPressed: () => _printStatement(ledgerEntries, startDate, endDate),
                            tooltip: 'Print',
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: AppTheme.primaryColor),
                            onPressed: () => _shareStatement(ledgerEntries, startDate, endDate),
                            tooltip: 'Share',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.customer.name,
                    style: AppTheme.headingSmall,
                  ),
                  if (startDate != null && endDate != null)
                    Text(
                      '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                      style: AppTheme.bodySmall,
                    ),
                ],
              ),
            ),

            // Statement Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Date / Description', style: AppTheme.labelMedium),
                  ),
                  Expanded(
                    child: Text('Debit/Credit', style: AppTheme.labelMedium, textAlign: TextAlign.right),
                  ),
                  Expanded(
                    child: Text('Balance', style: AppTheme.labelMedium, textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),

            Expanded(
              child: statement.isEmpty
                  ? const Center(child: Text('No transactions found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: statement.length,
                      itemBuilder: (context, index) {
                        final entry = statement[index];
                        final ledger = entry['ledger'] as LedgerModel;
                        final balance = entry['running_balance'] as double;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateFormat.format(ledger.transactionDate),
                                      style: AppTheme.labelSmall,
                                    ),
                                    Text(
                                      ledger.description,
                                      style: AppTheme.bodyMedium,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  ledger.isPayment
                                      ? '-${ledger.amount.toStringAsFixed(0)}'
                                      : '+${ledger.amount.toStringAsFixed(0)}',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: ledger.isPayment
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  balance.toStringAsFixed(0),
                                  style: AppTheme.labelLarge,
                                  textAlign: TextAlign.right,
                                ),
          ),
        ],
      ),
    );
                      },
                    ),
            ),
            // Footer with totals and actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(top: BorderSide(color: AppTheme.dividerColor)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Balance:', style: AppTheme.titleMedium),
                      Text(
                        'PKR ${widget.customer.outstandingBalance.toStringAsFixed(0)}',
                        style: AppTheme.priceText.copyWith(
                          color: widget.customer.hasOutstanding
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _saveStatement(ledgerEntries, startDate, endDate),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _printStatement(ledgerEntries, startDate, endDate),
                          icon: const Icon(Icons.print),
                          label: const Text('Print'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printStatement(List<LedgerModel> entries, DateTime? startDate, DateTime? endDate) async {
    try {
      final pdfService = PDFService();
      final prefs = await SharedPreferences.getInstance();
      final businessName = prefs.getString(AppConstants.businessNameKey) ?? 'Smart POS';

      final pdfData = await pdfService.generateCustomerStatement(
        customer: widget.customer,
        ledgerEntries: entries,
        businessName: businessName,
        startDate: startDate,
        endDate: endDate,
      );

      await pdfService.printPDF(pdfData, jobName: 'Statement - ${widget.customer.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    }
  }

  Future<void> _shareStatement(List<LedgerModel> entries, DateTime? startDate, DateTime? endDate) async {
    try {
      final pdfService = PDFService();
      final prefs = await SharedPreferences.getInstance();
      final businessName = prefs.getString(AppConstants.businessNameKey) ?? 'Smart POS';

      final pdfData = await pdfService.generateCustomerStatement(
        customer: widget.customer,
        ledgerEntries: entries,
        businessName: businessName,
        startDate: startDate,
        endDate: endDate,
      );

      final fileName = 'Statement_${widget.customer.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await pdfService.sharePDF(pdfData, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _saveStatement(List<LedgerModel> entries, DateTime? startDate, DateTime? endDate) async {
    try {
      final pdfService = PDFService();
      final prefs = await SharedPreferences.getInstance();
      final businessName = prefs.getString(AppConstants.businessNameKey) ?? 'Smart POS';

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
        );
      }

      final pdfData = await pdfService.generateCustomerStatement(
        customer: widget.customer,
        ledgerEntries: entries,
        businessName: businessName,
        startDate: startDate,
        endDate: endDate,
      );

      final fileName = 'Statement_${widget.customer.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Use share to let user save/share the PDF
      await pdfService.sharePDF(pdfData, fileName);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}

