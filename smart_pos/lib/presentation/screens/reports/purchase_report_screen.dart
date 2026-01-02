import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/stock_history_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../widgets/common/app_drawer.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<StockHistoryModel> _purchases = [];
  bool _isLoading = false;
  double _totalPurchaseValue = 0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<ProductProvider>();
    final allHistory = <StockHistoryModel>[];
    
    for (final product in provider.allProducts) {
      final history = await provider.getStockHistory(product.id);
      // Filter only stock_in (purchases)
      final purchases = history.where((h) => 
        h.operationType == AppConstants.stockIn
      );
      allHistory.addAll(purchases);
    }
    
    // Filter by date range
    final filtered = allHistory.where((log) {
      return log.operationDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             log.operationDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
    
    filtered.sort((a, b) => b.operationDate.compareTo(a.operationDate));
    
    // Calculate totals
    double totalValue = 0;
    int totalItems = 0;
    for (var purchase in filtered) {
      totalItems += purchase.quantityChange;
      // Note: We'd need cost price from product for accurate value
    }
    
    setState(() {
      _purchases = filtered;
      _totalPurchaseValue = totalValue;
      _totalItems = totalItems;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPurchases();
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Export Purchase Report', style: AppTheme.titleLarge),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('Share or print report'),
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart, color: Colors.green),
              ),
              title: const Text('Export as Excel'),
              subtitle: const Text('Open in spreadsheet app'),
              onTap: () {
                Navigator.pop(context);
                _exportExcel();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPDF() async {
    final purchaseProvider = context.read<PurchaseProvider>();
    await purchaseProvider.loadPurchases();
    
    final purchases = purchaseProvider.purchases.where((p) {
      return p.purchaseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             p.purchaseDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (purchases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No purchase data to export'), backgroundColor: AppTheme.warningColor),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Purchase Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Invoice', 'Date', 'Vendor', 'Total', 'Paid', 'Due', 'Status'],
              data: purchases.map((p) => [
                p.invoiceNumber,
                DateFormat('dd/MM').format(p.purchaseDate),
                p.vendorName ?? '-',
                currencyFormat.format(p.totalAmount),
                currencyFormat.format(p.paidAmount),
                currencyFormat.format(p.dueAmount),
                p.paymentStatus.toUpperCase(),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total: ${currencyFormat.format(purchases.fold(0.0, (sum, p) => sum + p.totalAmount))}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final directory = await getExternalStorageDirectory();
      final fileName = 'Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final filePath = '${directory?.path ?? '/storage/emulated/0/Download'}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) Navigator.pop(context);
      await Share.shareXFiles([XFile(filePath)], text: 'Purchase Report');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved: $fileName'), backgroundColor: AppTheme.snackBarAdd),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    final purchaseProvider = context.read<PurchaseProvider>();
    await purchaseProvider.loadPurchases();
    
    final purchases = purchaseProvider.purchases.where((p) {
      return p.purchaseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             p.purchaseDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (purchases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No purchase data to export'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Purchase Report'];

      sheet.appendRow([
        TextCellValue('Invoice #'),
        TextCellValue('Date'),
        TextCellValue('Vendor'),
        TextCellValue('Total'),
        TextCellValue('Paid'),
        TextCellValue('Due'),
        TextCellValue('Status'),
      ]);

      for (int i = 0; i < 7; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0D4D47'),
          fontColorHex: ExcelColor.white,
        );
      }

      for (var purchase in purchases) {
        sheet.appendRow([
          TextCellValue(purchase.invoiceNumber),
          TextCellValue(DateFormat('dd/MM/yyyy').format(purchase.purchaseDate)),
          TextCellValue(purchase.vendorName ?? '-'),
          DoubleCellValue(purchase.totalAmount),
          DoubleCellValue(purchase.paidAmount),
          DoubleCellValue(purchase.dueAmount),
          TextCellValue(purchase.paymentStatus.toUpperCase()),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        TextCellValue('${purchases.length} purchases'),
        DoubleCellValue(purchases.fold(0.0, (sum, p) => sum + p.totalAmount)),
        DoubleCellValue(purchases.fold(0.0, (sum, p) => sum + p.paidAmount)),
        DoubleCellValue(purchases.fold(0.0, (sum, p) => sum + p.dueAmount)),
        TextCellValue(''),
      ]);

      excel.delete('Sheet1');

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel');

      final directory = await getExternalStorageDirectory();
      final fileName = 'Purchase_Report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.xlsx';
      final filePath = '${directory?.path ?? '/storage/emulated/0/Download'}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (mounted) Navigator.pop(context);
      await OpenFile.open(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel saved: $fileName'),
            backgroundColor: AppTheme.snackBarAdd,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Report', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export',
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 5),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: ListTile(
              leading: const Icon(Icons.date_range, color: AppTheme.primaryColor),
              title: Text(
                '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: AppTheme.titleMedium,
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectDateRange,
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Purchases',
                    '${_purchases.length}',
                    Icons.shopping_cart,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Items Added',
                    '$_totalItems',
                    Icons.inventory_2,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Purchases List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Purchase History', style: AppTheme.titleLarge),
                TextButton(
                  onPressed: _loadPurchases,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),

          // Purchases List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _purchases.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _purchases.length,
                        itemBuilder: (context, index) {
                          return _buildPurchaseCard(_purchases[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(StockHistoryModel purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.productName ?? 'Product',
                  style: AppTheme.titleMedium,
                ),
                Text(
                  'Qty: ${purchase.quantityChange} units',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${purchase.quantityChange}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
              Text(
                DateFormat('dd-MMM').format(purchase.operationDate),
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.titleMedium.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(color: color),
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
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No purchases found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'No purchase records in the selected period',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

