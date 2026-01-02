import 'dart:io';
import 'dart:typed_data';
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
import '../../providers/report_provider.dart';
import '../../providers/pos_provider.dart';
import '../../widgets/common/app_drawer.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final provider = context.read<ReportProvider>();
    await provider.loadDailyReport(_endDate);
    setState(() => _isLoading = false);
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
      _loadReport();
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
            Text('Export Sales Report', style: AppTheme.titleLarge),
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
    final posProvider = context.read<POSProvider>();
    await posProvider.loadAllSales();
    
    final sales = posProvider.allSales.where((sale) {
      return sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             sale.saleDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sales data to export'), backgroundColor: AppTheme.warningColor),
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
              child: pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Invoice', 'Date', 'Customer', 'Total', 'Paid', 'Due'],
              data: sales.map((s) => [
                s.invoiceNumber,
                DateFormat('dd/MM').format(s.saleDate),
                s.customerName ?? 'Walk-in',
                currencyFormat.format(s.totalAmount),
                currencyFormat.format(s.paidAmount),
                currencyFormat.format(s.dueAmount),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total: ${currencyFormat.format(sales.fold(0.0, (sum, s) => sum + s.totalAmount))}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final directory = await getExternalStorageDirectory();
      final fileName = 'Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final filePath = '${directory?.path ?? '/storage/emulated/0/Download'}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) Navigator.pop(context);

      // Share the PDF
      await Share.shareXFiles([XFile(filePath)], text: 'Sales Report');

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
    final posProvider = context.read<POSProvider>();
    await posProvider.loadAllSales();
    
    final sales = posProvider.allSales.where((sale) {
      return sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             sale.saleDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sales data to export'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sales Report'];

      // Header
      sheet.appendRow([
        TextCellValue('Invoice #'),
        TextCellValue('Date'),
        TextCellValue('Customer'),
        TextCellValue('Items'),
        TextCellValue('Subtotal'),
        TextCellValue('Discount'),
        TextCellValue('Tax'),
        TextCellValue('Total'),
        TextCellValue('Paid'),
        TextCellValue('Due'),
        TextCellValue('Payment Method'),
      ]);

      // Style header
      for (int i = 0; i < 11; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0D4D47'),
          fontColorHex: ExcelColor.white,
        );
      }

      // Data rows
      for (var sale in sales) {
        sheet.appendRow([
          TextCellValue(sale.invoiceNumber),
          TextCellValue(DateFormat('dd/MM/yyyy').format(sale.saleDate)),
          TextCellValue(sale.customerName ?? 'Walk-in'),
          IntCellValue(sale.items?.length ?? 0),
          DoubleCellValue(sale.subtotal),
          DoubleCellValue(sale.discountAmount),
          DoubleCellValue(sale.taxAmount),
          DoubleCellValue(sale.totalAmount),
          DoubleCellValue(sale.paidAmount),
          DoubleCellValue(sale.dueAmount),
          TextCellValue(sale.paymentMethod),
        ]);
      }

      // Summary row
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        TextCellValue(''),
        IntCellValue(sales.length),
        DoubleCellValue(sales.fold(0.0, (sum, s) => sum + s.subtotal)),
        DoubleCellValue(sales.fold(0.0, (sum, s) => sum + s.discountAmount)),
        DoubleCellValue(sales.fold(0.0, (sum, s) => sum + s.taxAmount)),
        DoubleCellValue(sales.fold(0.0, (sum, s) => sum + s.totalAmount)),
        DoubleCellValue(sales.fold(0.0, (sum, s) => sum + s.paidAmount)),
        DoubleCellValue(sales.fold(0.0, (sum, s) => sum + s.dueAmount)),
        TextCellValue(''),
      ]);

      excel.delete('Sheet1');

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel');

      final directory = await getExternalStorageDirectory();
      final fileName = 'Sales_Report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.xlsx';
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
        title: Text('Sales Report', style: AppTheme.headingSmall),
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
      drawer: const AppDrawer(currentIndex: 4),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          return Column(
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
                        'Total Sales',
                        'PKR ${provider.totalSales.toStringAsFixed(0)}',
                        Icons.trending_up,
                        AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Transactions',
                        '${provider.totalTransactions}',
                        Icons.receipt_long,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Profit',
                        'PKR ${provider.totalProfit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Avg Sale',
                        'PKR ${provider.averageSale.toStringAsFixed(0)}',
                        Icons.analytics,
                        AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sales List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Sales', style: AppTheme.titleLarge),
                    TextButton(
                      onPressed: _loadReport,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),

              // Sales List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.salesData.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.salesData.length,
                            itemBuilder: (context, index) {
                              final sale = provider.salesData[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.cardDecoration,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.receipt,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale.invoiceNumber,
                                            style: AppTheme.titleMedium,
                                          ),
                                          Text(
                                            '${sale.customerName ?? "Walk-in"} • ${sale.totalItems} items',
                                            style: AppTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'PKR ${sale.totalAmount.toStringAsFixed(0)}',
                                          style: AppTheme.priceText,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: sale.isPaid
                                                ? AppTheme.successColor.withOpacity(0.1)
                                                : AppTheme.warningColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            sale.isPaid ? 'Paid' : 'Due',
                                            style: AppTheme.labelMedium.copyWith(
                                              color: sale.isPaid
                                                  ? AppTheme.successColor
                                                  : AppTheme.warningColor,
                                            ),
                                          ),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No sales found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'No sales in the selected period',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

