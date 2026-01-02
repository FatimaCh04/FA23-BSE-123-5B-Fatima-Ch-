import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/excel_export_service.dart';
import '../../providers/report_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    final provider = context.read<ReportProvider>();
    provider.loadDailyReport(_selectedDate);
    provider.loadStockReport();
    provider.loadCustomerReport();
    provider.loadTopProducts();
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
                color: const Color(0xFF06B6D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bar_chart, color: Color(0xFF06B6D4), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reports',
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download, color: AppTheme.primaryColor, size: 20),
            ),
            onPressed: () => _showExportDialog(),
            tooltip: 'Export Excel',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Monthly'),
            Tab(text: 'Stock'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReport(),
          _buildMonthlyReport(),
          _buildStockReport(),
          _buildCustomerReport(),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Export Reports',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose report type and format',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildExportOptionWithFormat(
                icon: Icons.receipt_long,
                title: 'All Sales Report',
                subtitle: 'Export all sales transactions',
                onPdfTap: () => _exportSalesReportPdf(),
                onExcelTap: () => _exportSalesReport(),
              ),
              _buildExportOptionWithFormat(
                icon: Icons.list_alt,
                title: 'Sales with Items',
                subtitle: 'Detailed sales with product items',
                onPdfTap: () => _exportSalesWithItemsPdf(),
                onExcelTap: () => _exportSalesWithItems(),
              ),
              _buildExportOptionWithFormat(
                icon: Icons.inventory_2,
                title: 'Products Inventory',
                subtitle: 'Export all products with stock',
                onPdfTap: () => _exportProductsReportPdf(),
                onExcelTap: () => _exportProductsReport(),
              ),
              _buildExportOptionWithFormat(
                icon: Icons.people,
                title: 'Customers List',
                subtitle: 'Export all customers data',
                onPdfTap: () => _exportCustomersReportPdf(),
                onExcelTap: () => _exportCustomersReport(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildExportOptionWithFormat({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPdfTap,
    required VoidCallback onExcelTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // PDF Button
          InkWell(
            onTap: onPdfTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 4),
                  Text('PDF', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Excel Button
          InkWell(
            onTap: onExcelTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_chart, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 4),
                  Text('Excel', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSalesReport() async {
    Navigator.pop(context);
    _showLoadingDialog('Exporting Sales Report...');
    
    try {
      final posProvider = context.read<POSProvider>();
      await posProvider.loadAllSales();
      final sales = posProvider.allSales;
      
      debugPrint('[Export] Sales count: ${sales.length}');
      
      if (sales.isEmpty) {
        Navigator.pop(context);
        _showMessage('No sales data to export. Make a sale first!', isError: true);
        return;
      }
      
      final excelService = ExcelExportService();
      final filePath = await excelService.exportSalesToExcel(sales);
      
      Navigator.pop(context);
      
      if (filePath != null) {
        debugPrint('[Export] File created: $filePath');
        _showExportSuccessDialog(filePath);
      } else {
        _showMessage('Failed to create Excel file', isError: true);
      }
    } catch (e) {
      debugPrint('[Export] Error: $e');
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _exportSalesWithItems() async {
    Navigator.pop(context);
    _showLoadingDialog('Exporting Sales with Items...');
    
    try {
      final posProvider = context.read<POSProvider>();
      await posProvider.loadAllSales();
      final sales = posProvider.allSales;
      
      if (sales.isEmpty) {
        Navigator.pop(context);
        _showMessage('No sales data to export', isError: true);
        return;
      }
      
      final excelService = ExcelExportService();
      final filePath = await excelService.exportSalesWithItems(sales);
      
      Navigator.pop(context);
      
      if (filePath != null) {
        _showExportSuccessDialog(filePath);
      } else {
        _showMessage('Failed to export', isError: true);
      }
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _exportProductsReport() async {
    Navigator.pop(context);
    _showLoadingDialog('Exporting Products...');
    
    try {
      final productProvider = context.read<ProductProvider>();
      final products = productProvider.allProducts;
      
      if (products.isEmpty) {
        Navigator.pop(context);
        _showMessage('No products to export', isError: true);
        return;
      }
      
      final excelService = ExcelExportService();
      final filePath = await excelService.exportProductsToExcel(products);
      
      Navigator.pop(context);
      
      if (filePath != null) {
        _showExportSuccessDialog(filePath);
      } else {
        _showMessage('Failed to export', isError: true);
      }
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _exportCustomersReport() async {
    Navigator.pop(context);
    _showLoadingDialog('Exporting Customers...');
    
    try {
      final customerProvider = context.read<CustomerProvider>();
      final customers = customerProvider.customers;
      
      if (customers.isEmpty) {
        Navigator.pop(context);
        _showMessage('No customers to export', isError: true);
        return;
      }
      
      final excelService = ExcelExportService();
      final filePath = await excelService.exportCustomersToExcel(customers);
      
      Navigator.pop(context);
      
      if (filePath != null) {
        _showExportSuccessDialog(filePath);
      } else {
        _showMessage('Failed to export', isError: true);
      }
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  // ======================== PDF EXPORT METHODS ========================
  
  Future<void> _exportSalesReportPdf() async {
    Navigator.pop(context);
    _showLoadingDialog('Generating Sales Report PDF...');
    
    try {
      final posProvider = context.read<POSProvider>();
      await posProvider.loadAllSales();
      final sales = posProvider.allSales;
      
      if (sales.isEmpty) {
        Navigator.pop(context);
        _showMessage('No sales data to export', isError: true);
        return;
      }
      
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.teal)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                pw.Text('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          build: (context) {
            final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
            final totalPaid = sales.fold<double>(0, (sum, s) => sum + s.paidAmount);
            final totalDue = totalSales - totalPaid;
            
            return [
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Sales', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('${sales.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Amount', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(currencyFormat.format(totalSales), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Paid', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(currencyFormat.format(totalPaid), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Due', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(currencyFormat.format(totalDue), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                      ],
                    ),
                  ],
                ),
              ),
              // Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                cellPadding: const pw.EdgeInsets.all(8),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.center,
                },
                headers: ['Invoice', 'Date', 'Customer', 'Amount', 'Paid', 'Status'],
                data: sales.map((s) => [
                  s.invoiceNumber,
                  DateFormat('dd/MM/yyyy').format(s.saleDate),
                  s.customerName ?? 'Walk-in',
                  currencyFormat.format(s.totalAmount),
                  currencyFormat.format(s.paidAmount),
                  s.dueAmount > 0 ? 'CREDIT' : 'PAID',
                ]).toList(),
              ),
            ];
          },
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      Navigator.pop(context);
      await Share.shareXFiles([XFile(filePath)], text: 'Sales Report');
      
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _exportSalesWithItemsPdf() async {
    Navigator.pop(context);
    _showLoadingDialog('Generating Sales with Items PDF...');
    
    try {
      final posProvider = context.read<POSProvider>();
      await posProvider.loadAllSales();
      final sales = posProvider.allSales;
      
      if (sales.isEmpty) {
        Navigator.pop(context);
        _showMessage('No sales data to export', isError: true);
        return;
      }
      
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.teal)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sales with Items', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                pw.Text('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          build: (context) {
            List<pw.Widget> widgets = [];
            
            for (var sale in sales) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(sale.invoiceNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(DateFormat('dd/MM/yyyy').format(sale.saleDate)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Customer: ${sale.customerName ?? 'Walk-in'}'),
                          pw.Text(currencyFormat.format(sale.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      if (sale.items.isNotEmpty) ...[
                        pw.Table.fromTextArray(
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          cellStyle: const pw.TextStyle(fontSize: 9),
                          cellPadding: const pw.EdgeInsets.all(4),
                          headers: ['Product', 'Qty', 'Price', 'Total'],
                          data: sale.items.map((item) => [
                            item.productName,
                            item.quantity.toString(),
                            currencyFormat.format(item.unitPrice),
                            currencyFormat.format(item.totalPrice),
                          ]).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            
            return widgets;
          },
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Sales_Items_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      Navigator.pop(context);
      await Share.shareXFiles([XFile(filePath)], text: 'Sales with Items Report');
      
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _exportProductsReportPdf() async {
    Navigator.pop(context);
    _showLoadingDialog('Generating Products PDF...');
    
    try {
      final productProvider = context.read<ProductProvider>();
      final products = productProvider.allProducts;
      
      if (products.isEmpty) {
        Navigator.pop(context);
        _showMessage('No products to export', isError: true);
        return;
      }
      
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.teal)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Products Inventory', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                pw.Text('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          build: (context) {
            final totalStock = products.fold<int>(0, (sum, p) => sum + p.quantity);
            final totalValue = products.fold<double>(0, (sum, p) => sum + (p.salePrice * p.quantity));
            
            return [
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Products', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('${products.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Stock', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('$totalStock', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Stock Value', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(currencyFormat.format(totalValue), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                      ],
                    ),
                  ],
                ),
              ),
              // Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                cellPadding: const pw.EdgeInsets.all(8),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                headers: ['Product Name', 'Stock', 'Cost Price', 'Selling Price', 'Value'],
                data: products.map((p) => [
                  p.name,
                  p.quantity.toString(),
                  currencyFormat.format(p.costPrice),
                  currencyFormat.format(p.salePrice),
                  currencyFormat.format(p.salePrice * p.quantity),
                ]).toList(),
              ),
            ];
          },
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Products_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      Navigator.pop(context);
      await Share.shareXFiles([XFile(filePath)], text: 'Products Inventory Report');
      
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _exportCustomersReportPdf() async {
    Navigator.pop(context);
    _showLoadingDialog('Generating Customers PDF...');
    
    try {
      final customerProvider = context.read<CustomerProvider>();
      final customers = customerProvider.customers;
      
      if (customers.isEmpty) {
        Navigator.pop(context);
        _showMessage('No customers to export', isError: true);
        return;
      }
      
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.teal)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Customers List', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                pw.Text('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          build: (context) {
            final totalReceivable = customers.fold<double>(0, (sum, c) => sum + c.outstandingBalance);
            
            return [
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Customers', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('${customers.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Receivable', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(currencyFormat.format(totalReceivable), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: totalReceivable > 0 ? PdfColors.red700 : PdfColors.green700)),
                      ],
                    ),
                  ],
                ),
              ),
              // Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                cellPadding: const pw.EdgeInsets.all(8),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                headers: ['Name', 'Phone', 'Email', 'Balance'],
                data: customers.map((c) => [
                  c.name,
                  c.phone ?? '-',
                  c.email ?? '-',
                  currencyFormat.format(c.outstandingBalance),
                ]).toList(),
              ),
            ];
          },
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Customers_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      Navigator.pop(context);
      await Share.shareXFiles([XFile(filePath)], text: 'Customers Report');
      
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Error: $e', isError: true);
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showExportSuccessDialog(String filePath) {
    final excelService = ExcelExportService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Export Complete'),
          ],
        ),
        content: const Text('Excel file has been created successfully. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              excelService.openExcelFile(filePath);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              excelService.shareExcelFile(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDailyReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Date Selector
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate =
                            _selectedDate.subtract(const Duration(days: 1));
                      });
                      provider.loadDailyReport(_selectedDate);
                    },
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context, provider),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: AppTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedDate.isBefore(
                            DateTime.now().subtract(const Duration(days: 1)))
                        ? () {
                            setState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 1));
                            });
                            provider.loadDailyReport(_selectedDate);
                          }
                        : null,
                  ),
                ],
              ),
            ),

            // Stats Cards
            if (!provider.isLoading) ...[
              Padding(
                padding: const EdgeInsets.all(16),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Profit',
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
            ],

            // Sales List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.salesData.isEmpty
                      ? _buildEmptyState('No sales on this day')
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
                                      color:
                                          AppTheme.primaryColor.withOpacity(0.1),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  Text(
                                    'PKR ${sale.totalAmount.toStringAsFixed(0)}',
                                    style: AppTheme.priceText,
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

  Widget _buildMonthlyReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Month Selector
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 1) {
                          _selectedMonth = 12;
                          _selectedYear--;
                        } else {
                          _selectedMonth--;
                        }
                      });
                      provider.loadMonthlyReport(_selectedYear, _selectedMonth);
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy')
                        .format(DateTime(_selectedYear, _selectedMonth)),
                    style: AppTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_selectedYear < DateTime.now().year ||
                            (_selectedYear == DateTime.now().year &&
                                _selectedMonth < DateTime.now().month))
                        ? () {
                            setState(() {
                              if (_selectedMonth == 12) {
                                _selectedMonth = 1;
                                _selectedYear++;
                              } else {
                                _selectedMonth++;
                              }
                            });
                            provider.loadMonthlyReport(
                                _selectedYear, _selectedMonth);
                          }
                        : null,
                  ),
                ],
              ),
            ),

            // Load monthly data button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () =>
                    provider.loadMonthlyReport(_selectedYear, _selectedMonth),
                child: const Text('Load Monthly Report'),
              ),
            ),

            // Stats
            if (!provider.isLoading) ...[
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
                        'Total Profit',
                        'PKR ${provider.totalProfit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        AppTheme.accentColor,
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
                        'Transactions',
                        '${provider.totalTransactions}',
                        Icons.receipt_long,
                        AppTheme.primaryColor,
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
            ],

            // Daily breakdown
            if (provider.dailySales.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Daily Breakdown', style: AppTheme.titleLarge),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.dailySales.length,
                  itemBuilder: (context, index) {
                    final entry = provider.dailySales.entries.toList()[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: AppTheme.bodyMedium),
                          Text(
                            'PKR ${entry.value.toStringAsFixed(0)}',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStockReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Stock Value',
                      'PKR ${provider.totalStockValue.toStringAsFixed(0)}',
                      Icons.inventory_2,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Cost Value',
                      'PKR ${provider.totalCostValue.toStringAsFixed(0)}',
                      Icons.price_check,
                      AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      '${provider.lowStockCount}',
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Out of Stock',
                      '${provider.outOfStockCount}',
                      Icons.error_outline,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),

              // Category Breakdown
              const SizedBox(height: 24),
              Text('Stock by Category', style: AppTheme.titleLarge),
              const SizedBox(height: 16),
              ...provider.salesByCategory.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: AppTheme.bodyMedium),
                      Text(
                        'PKR ${entry.value.toStringAsFixed(0)}',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Top Products
              if (provider.topProducts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Top Selling Products', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                ...provider.topProducts.take(5).map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['productName'] ?? '',
                                style: AppTheme.labelLarge,
                              ),
                              Text(
                                'Sold: ${product['quantity']} units',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'PKR ${(product['revenue'] ?? 0).toStringAsFixed(0)}',
                          style: AppTheme.priceText,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Customers',
                      '${provider.activeCustomers}',
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Receivables',
                      'PKR ${provider.totalReceivables.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),

              // Top Customers
              if (provider.topCustomers.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Top Customers by Purchase', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                ...provider.topCustomers.map((customer) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            (customer['name'] as String)[0].toUpperCase(),
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer['name'] ?? '',
                                style: AppTheme.titleMedium,
                              ),
                              if ((customer['outstanding'] ?? 0) > 0)
                                Text(
                                  'Outstanding: PKR ${(customer['outstanding']).toStringAsFixed(0)}',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'PKR ${(customer['totalPurchases'] ?? 0).toStringAsFixed(0)}',
                          style: AppTheme.priceText,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
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

  Future<void> _selectDate(BuildContext context, ReportProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      provider.loadDailyReport(picked);
    }
  }
}

