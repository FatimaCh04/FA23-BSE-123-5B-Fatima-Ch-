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
import '../../providers/report_provider.dart';
import '../../widgets/common/app_drawer.dart';

class ItemSalesReportScreen extends StatefulWidget {
  const ItemSalesReportScreen({super.key});

  @override
  State<ItemSalesReportScreen> createState() => _ItemSalesReportScreenState();
}

class _ItemSalesReportScreenState extends State<ItemSalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String _sortBy = 'quantity'; // quantity, revenue, name

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final provider = context.read<ReportProvider>();
    await provider.loadTopProducts();
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
            Text('Export Item Sales', style: AppTheme.titleLarge),
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
    final provider = context.read<ReportProvider>();
    final products = provider.topProducts;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No item sales data to export'), backgroundColor: AppTheme.warningColor),
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
              child: pw.Text('Item Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Product', 'SKU', 'Qty Sold', 'Revenue'],
              data: products.map((p) => [
                p['name'] ?? '-',
                p['sku'] ?? '-',
                '${p['quantity'] ?? 0}',
                currencyFormat.format((p['revenue'] ?? 0).toDouble()),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Revenue: ${currencyFormat.format(products.fold(0.0, (sum, p) => sum + ((p['revenue'] ?? 0) as num).toDouble()))}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final directory = await getExternalStorageDirectory();
      final fileName = 'Item_Sales_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final filePath = '${directory?.path ?? '/storage/emulated/0/Download'}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) Navigator.pop(context);
      await Share.shareXFiles([XFile(filePath)], text: 'Item Sales Report');

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
    final provider = context.read<ReportProvider>();
    final products = provider.topProducts;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No item sales data to export'),
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
      final sheet = excel['Item Sales'];

      sheet.appendRow([
        TextCellValue('Product Name'),
        TextCellValue('SKU'),
        TextCellValue('Qty Sold'),
        TextCellValue('Revenue'),
        TextCellValue('Avg Price'),
      ]);

      for (int i = 0; i < 5; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0D4D47'),
          fontColorHex: ExcelColor.white,
        );
      }

      for (var product in products) {
        sheet.appendRow([
          TextCellValue(product['name'] ?? '-'),
          TextCellValue(product['sku'] ?? '-'),
          IntCellValue(product['quantity'] ?? 0),
          DoubleCellValue((product['revenue'] ?? 0).toDouble()),
          DoubleCellValue((product['avgPrice'] ?? 0).toDouble()),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue('${products.length} items'),
        IntCellValue(products.fold(0, (sum, p) => sum + ((p['quantity'] ?? 0) as int))),
        DoubleCellValue(products.fold(0.0, (sum, p) => sum + ((p['revenue'] ?? 0) as num).toDouble())),
        TextCellValue(''),
      ]);

      excel.delete('Sheet1');

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel');

      final directory = await getExternalStorageDirectory();
      final fileName = 'Item_Sales_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.xlsx';
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
        title: Text('Item Sales Report', style: AppTheme.headingSmall),
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
      drawer: const AppDrawer(currentIndex: 6),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          final products = List<Map<String, dynamic>>.from(provider.topProducts);
          
          // Sort based on selection
          if (_sortBy == 'quantity') {
            products.sort((a, b) => (b['quantity'] ?? 0).compareTo(a['quantity'] ?? 0));
          } else if (_sortBy == 'revenue') {
            products.sort((a, b) => (b['revenue'] ?? 0).compareTo(a['revenue'] ?? 0));
          } else {
            products.sort((a, b) => (a['productName'] ?? '').compareTo(b['productName'] ?? ''));
          }

          // Calculate totals
          int totalQuantity = 0;
          double totalRevenue = 0;
          for (var product in products) {
            totalQuantity += (product['quantity'] ?? 0) as int;
            totalRevenue += (product['revenue'] ?? 0) as double;
          }

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
                        'Total Items Sold',
                        '$totalQuantity',
                        Icons.inventory_2,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Revenue',
                        'PKR ${totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sort Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppTheme.cardDecoration,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      icon: const Icon(Icons.sort),
                      items: const [
                        DropdownMenuItem(value: 'quantity', child: Text('Sort by Quantity')),
                        DropdownMenuItem(value: 'revenue', child: Text('Sort by Revenue')),
                        DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Products List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Product Sales', style: AppTheme.titleLarge),
                    Text(
                      '${products.length} items',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Products List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(products[index], index + 1);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int rank) {
    final quantity = product['quantity'] ?? 0;
    final revenue = (product['revenue'] ?? 0).toDouble();
    final productName = product['productName'] ?? 'Unknown Product';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank <= 3 
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.textLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTheme.labelLarge.copyWith(
                  color: rank <= 3 ? AppTheme.accentColor : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: AppTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${revenue.toStringAsFixed(0)}',
                style: AppTheme.priceText,
              ),
              Text(
                'revenue',
                style: AppTheme.labelSmall,
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
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No item sales found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'No products sold in the selected period',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

