import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ledger_model.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final dateFormat = DateFormat('dd MMM yyyy');
  final currencyFormat = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      provider.loadAllLedgerEntries();
      provider.loadCustomers();
    });
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
                color: const Color(0xFFEC4899).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFFEC4899), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ledger',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF2D3748)),
            onPressed: () => _showFilterSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3748)),
            onPressed: () {
              context.read<CustomerProvider>().loadAllLedgerEntries();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list_alt)),
            Tab(text: 'Receivables', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Transactions', icon: Icon(Icons.swap_horiz)),
          ],
        ),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Active Filters Display
              _buildActiveFilters(provider),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllLedgerTab(provider),
                    _buildReceivablesTab(provider),
                    _buildTransactionsTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildActiveFilters(CustomerProvider provider) {
    final hasFilters = provider.ledgerDateFilter != 'all' ||
        provider.selectedCustomerIdForLedger != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (provider.ledgerDateFilter != 'all')
                  _buildFilterChip(
                    _getDateFilterLabel(provider.ledgerDateFilter),
                    () => provider.setLedgerDateFilter('all'),
                  ),
                if (provider.selectedCustomerIdForLedger != null)
                  _buildFilterChip(
                    provider.getCustomerById(provider.selectedCustomerIdForLedger!)?.name ?? 'Customer',
                    () => provider.setLedgerCustomerFilter(null),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => provider.clearLedgerFilters(),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: AppTheme.labelSmall),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppTheme.surfaceColor,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _getDateFilterLabel(String filter) {
    switch (filter) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'custom':
        return 'Custom Range';
      default:
        return 'All Time';
    }
  }

  Widget _buildAllLedgerTab(CustomerProvider provider) {
    final stats = provider.ledgerStatistics;

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Receivables',
                  currencyFormat.format(provider.totalReceivables),
                        Icons.account_balance_wallet,
                        AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                  'Transactions',
                  '${stats['total_transactions']}',
                  Icons.receipt_long,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

        // Quick Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
              _buildMiniStat(
                'Debits/Credits',
                '${stats['debit_count']}',
                AppTheme.errorColor,
              ),
              const SizedBox(width: 8),
              _buildMiniStat(
                'Payments',
                '${stats['payment_count']}',
                AppTheme.successColor,
              ),
              const SizedBox(width: 8),
              _buildMiniStat(
                'Customers',
                '${provider.customersWithOutstandingCount}',
                AppTheme.primaryColor,
              ),
                  ],
                ),
              ),
        const SizedBox(height: 16),

        // Ledger Entries List
              Expanded(
          child: provider.ledgerEntries.isEmpty
              ? _buildEmptyState('No ledger entries found')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.ledgerEntries.length,
                        itemBuilder: (context, index) {
                    final entry = provider.ledgerEntries[index];
                    return _buildLedgerEntryCard(entry, provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReceivablesTab(CustomerProvider provider) {
    final customersWithBalance = provider.customersWithOutstanding;

    return Column(
                              children: [
        // Total Receivables Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.warningColor, AppTheme.warningColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.warningColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
                                  child: Column(
                                    children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
              const SizedBox(height: 12),
                                      Text(
                currencyFormat.format(provider.totalReceivables),
                style: AppTheme.headingMedium.copyWith(color: Colors.white),
                                      ),
              Text(
                'Total Receivables',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
                                  ),
              const SizedBox(height: 8),
                                    Text(
                '${customersWithBalance.length} customers with outstanding balance',
                style: AppTheme.labelSmall.copyWith(color: Colors.white.withOpacity(0.8)),
                                    ),
                                  ],
                                ),
        ),

        // Customers List
        Expanded(
          child: customersWithBalance.isEmpty
              ? _buildSuccessState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customersWithBalance.length,
                  itemBuilder: (context, index) {
                    final customer = customersWithBalance[index];
                    return _buildReceivableCard(customer, provider);
                        },
                      ),
              ),
      ],
    );
  }

  Widget _buildTransactionsTab(CustomerProvider provider) {
    // Group transactions by date
    final entries = provider.ledgerEntries;
    Map<String, List<LedgerModel>> groupedEntries = {};

    for (var entry in entries) {
      final dateKey = dateFormat.format(entry.transactionDate);
      groupedEntries.putIfAbsent(dateKey, () => []);
      groupedEntries[dateKey]!.add(entry);
    }

    return entries.isEmpty
        ? _buildEmptyState('No transactions found')
        : ListView.builder(
                  padding: const EdgeInsets.all(16),
            itemCount: groupedEntries.keys.length,
            itemBuilder: (context, index) {
              final dateKey = groupedEntries.keys.elementAt(index);
              final dayEntries = groupedEntries[dateKey]!;

              // Calculate day totals
              double dayDebits = 0;
              double dayPayments = 0;
              for (var e in dayEntries) {
                if (e.isPayment) {
                  dayPayments += e.amount;
                } else {
                  dayDebits += e.amount;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(dateKey, style: AppTheme.titleMedium),
                        Row(
                          children: [
                            if (dayDebits > 0)
                              Text(
                                '+${currencyFormat.format(dayDebits)}',
                                style: AppTheme.labelSmall.copyWith(color: AppTheme.errorColor),
                              ),
                            if (dayDebits > 0 && dayPayments > 0) const Text(' | '),
                            if (dayPayments > 0)
                              Text(
                                '-${currencyFormat.format(dayPayments)}',
                                style: AppTheme.labelSmall.copyWith(color: AppTheme.successColor),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Day Entries
                  ...dayEntries.map((entry) => _buildCompactLedgerCard(entry)),

                  const SizedBox(height: 16),
            ],
          );
        },
          );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(color: Colors.white),
          ),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
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
              style: AppTheme.labelSmall.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerEntryCard(LedgerModel entry, CustomerProvider provider) {
    final isPayment = entry.isPayment;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => _showEntryDetails(entry, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction Type Icon
              Container(
      padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPayment
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isPayment ? AppTheme.successColor : AppTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.customerName ?? 'Unknown Customer',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.description,
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(entry.transactionDate),
                      style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

              // Amount & Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment ? '-' : '+'}${currencyFormat.format(entry.amount)}',
                    style: AppTheme.titleMedium.copyWith(
                      color: isPayment ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bal: ${currencyFormat.format(entry.balanceAfter)}',
                      style: AppTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLedgerCard(LedgerModel entry) {
    final isPayment = entry.isPayment;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPayment
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPayment ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPayment ? AppTheme.successColor : AppTheme.errorColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.customerName ?? 'Customer',
                  style: AppTheme.labelLarge,
                ),
                Text(
                  entry.description,
                  style: AppTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isPayment ? '-' : '+'}${currencyFormat.format(entry.amount)}',
            style: AppTheme.labelLarge.copyWith(
              color: isPayment ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(CustomerModel customer, CustomerProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Customer Avatar
          CircleAvatar(
            backgroundColor: AppTheme.warningColor.withOpacity(0.1),
            radius: 25,
            child: Text(
              customer.name[0].toUpperCase(),
              style: AppTheme.titleMedium.copyWith(color: AppTheme.warningColor),
            ),
          ),
          const SizedBox(width: 12),

          // Customer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: AppTheme.titleMedium),
                Text(
                  'Total: ${currencyFormat.format(customer.totalPurchases)}',
                  style: AppTheme.bodySmall,
                ),
                if (customer.lastPurchaseDate != null)
                  Text(
                    'Last: ${dateFormat.format(customer.lastPurchaseDate!)}',
                    style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),

          // Outstanding & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(customer.outstandingBalance),
                style: AppTheme.priceText.copyWith(color: AppTheme.warningColor),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showPaymentDialog(customer, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payment, size: 16, color: AppTheme.successColor),
                      const SizedBox(width: 4),
              Text(
                        'Receive',
                        style: AppTheme.labelSmall.copyWith(color: AppTheme.successColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          Icon(Icons.receipt_long, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
            size: 64,
            color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Outstanding Balance!',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.successColor),
          ),
          const SizedBox(height: 8),
          Text(
            'All customers have cleared their dues',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LedgerFilterSheet(),
    );
  }

  void _showEntryDetails(LedgerModel entry, CustomerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction Details', style: AppTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            _buildDetailRow('Customer', entry.customerName ?? 'Unknown'),
            _buildDetailRow('Type', entry.transactionType.toUpperCase()),
            _buildDetailRow('Amount', currencyFormat.format(entry.amount)),
            _buildDetailRow('Balance Before', currencyFormat.format(entry.balanceBefore)),
            _buildDetailRow('Balance After', currencyFormat.format(entry.balanceAfter)),
            _buildDetailRow('Date', dateFormat.format(entry.transactionDate)),
            _buildDetailRow('Description', entry.description),
            if (entry.referenceId != null)
              _buildDetailRow('Reference', entry.referenceId!),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showReverseEntryDialog(entry, provider);
                    },
                    icon: const Icon(Icons.undo, color: AppTheme.errorColor),
                    label: const Text('Reverse Entry', style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showReverseEntryDialog(LedgerModel entry, CustomerProvider provider) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reverse Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create a reverse entry to cancel this transaction.',
            style: AppTheme.bodySmall,
          ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for reversal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
          ),
        ],
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              final success = await provider.reverseLedgerEntry(
                entry.id,
                reasonController.text.trim(),
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Entry reversed successfully' : 'Failed to reverse entry'),
                  ),
                );
              }
            },
            child: const Text('Reverse'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(CustomerModel customer, CustomerProvider provider) {
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
            Text(customer.name, style: AppTheme.titleMedium),
            Text(
              'Outstanding: ${currencyFormat.format(customer.outstandingBalance)}',
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
                final success = await provider.recordPayment(
                  customerId: customer.id,
                  amount: amount,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Payment recorded' : 'Payment failed')),
                  );
                }
              }
            },
            child: const Text('Receive'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionSheet(),
    );
  }
}

// Filter Sheet
class _LedgerFilterSheet extends StatefulWidget {
  @override
  State<_LedgerFilterSheet> createState() => _LedgerFilterSheetState();
}

class _LedgerFilterSheetState extends State<_LedgerFilterSheet> {
  String _selectedDateFilter = 'all';
  String? _selectedCustomerId;
  DateTime? _startDate;
  DateTime? _endDate;
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final provider = context.read<CustomerProvider>();
    _selectedDateFilter = provider.ledgerDateFilter;
    _selectedCustomerId = provider.selectedCustomerIdForLedger;
    _startDate = provider.ledgerStartDate;
    _endDate = provider.ledgerEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Ledger', style: AppTheme.headingSmall),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Filter
                  Text('Date Range', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDateFilterChip('all', 'All Time'),
                      _buildDateFilterChip('today', 'Today'),
                      _buildDateFilterChip('week', 'This Week'),
                      _buildDateFilterChip('month', 'This Month'),
                      _buildDateFilterChip('custom', 'Custom'),
                    ],
                  ),

                  // Custom Date Range
                  if (_selectedDateFilter == 'custom') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start Date', style: AppTheme.labelSmall),
                                  Text(
                                    _startDate != null ? dateFormat.format(_startDate!) : 'Select',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('End Date', style: AppTheme.labelSmall),
                                  Text(
                                    _endDate != null ? dateFormat.format(_endDate!) : 'Select',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Customer Filter
                  Text('Customer', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  Consumer<CustomerProvider>(
                    builder: (context, provider, _) {
                      final customers = provider.allCustomers.where((c) => c.isActive).toList();
                      return DropdownButtonFormField<String?>(
                        value: _selectedCustomerId,
                        decoration: InputDecoration(
                          hintText: 'All Customers',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Customers'),
                          ),
                          ...customers.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCustomerId = value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = 'all';
                        _selectedCustomerId = null;
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String value, String label) {
    final isSelected = _selectedDateFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedDateFilter = value);
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _applyFilters() {
    final provider = context.read<CustomerProvider>();

    if (_selectedDateFilter == 'custom') {
      provider.setLedgerCustomDateRange(_startDate, _endDate);
    } else {
      provider.setLedgerDateFilter(_selectedDateFilter);
    }

    provider.setLedgerCustomerFilter(_selectedCustomerId);

    Navigator.pop(context);
  }
}

// Add Transaction Sheet
class _AddTransactionSheet extends StatefulWidget {
  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  String _transactionType = 'debit'; // debit, payment
  String? _selectedCustomerId;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Transaction', style: AppTheme.headingSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type
                    Text('Transaction Type', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeOption(
                            'debit',
                            'Add Debit',
                            Icons.arrow_upward,
                            AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeOption(
                            'payment',
                            'Receive Payment',
                            Icons.arrow_downward,
                            AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Customer Selection
                    Text('Customer', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    Consumer<CustomerProvider>(
                      builder: (context, provider, _) {
                        final customers = provider.allCustomers
                            .where((c) => c.isActive && c.customerType == AppConstants.customerRegular)
                            .toList();
                        return DropdownButtonFormField<String?>(
                          value: _selectedCustomerId,
                          decoration: InputDecoration(
                            hintText: 'Select Customer',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null ? 'Please select a customer' : null,
                          items: customers
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(c.name),
                                        if (c.hasOutstanding)
                                          Text(
                                            'PKR ${c.outstandingBalance.toStringAsFixed(0)}',
                                            style: AppTheme.labelSmall.copyWith(color: AppTheme.warningColor),
                                          ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedCustomerId = value);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Amount
                    Text('Amount', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixText: 'PKR ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter amount';
                        if (double.tryParse(value) == null) return 'Invalid amount';
                        if (double.parse(value) <= 0) return 'Amount must be greater than 0';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text('Description', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: _transactionType == 'debit'
                            ? 'e.g., Opening balance, Adjustment'
                            : 'e.g., Cash payment, Bank transfer',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter description';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _transactionType == 'debit' ? AppTheme.warningColor : AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _transactionType == 'debit' ? 'Add Debit Entry' : 'Record Payment',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon, Color color) {
    final isSelected = _transactionType == type;
    return InkWell(
      onTap: () => setState(() => _transactionType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.labelLarge.copyWith(
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CustomerProvider>();
    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();

    bool success;
    if (_transactionType == 'debit') {
      success = await provider.addDebit(
        customerId: _selectedCustomerId!,
        amount: amount,
        description: description,
      );
    } else {
      success = await provider.recordPayment(
        customerId: _selectedCustomerId!,
        amount: amount,
        notes: description,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${_transactionType == 'debit' ? 'Debit added' : 'Payment recorded'} successfully'
              : 'Transaction failed'),
        ),
      );
    }
  }
}
