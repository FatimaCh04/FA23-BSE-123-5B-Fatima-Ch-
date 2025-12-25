import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/ledger_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/stock_history_model.dart';
import '../../core/constants/app_constants.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final dateFormat = DateFormat('dd MMM yyyy');
  final currencyFormat = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

  // Generate Customer Statement PDF
  Future<Uint8List> generateCustomerStatement({
    required CustomerModel customer,
    required List<LedgerModel> ledgerEntries,
    String? businessName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Calculate totals
    double totalDebits = 0;
    double totalCredits = 0;
    double totalPayments = 0;

    for (var entry in ledgerEntries) {
      if (entry.isDebit) {
        totalDebits += entry.amount;
      } else if (entry.isCredit) {
        totalCredits += entry.amount;
      } else if (entry.isPayment) {
        totalPayments += entry.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildStatementHeader(
          businessName: businessName ?? 'Smart POS',
          customer: customer,
          startDate: startDate,
          endDate: endDate,
        ),
        footer: (context) => _buildPageFooter(context, now),
        build: (context) => [
          // Customer Details Card
          _buildCustomerDetailsCard(customer),
          pw.SizedBox(height: 20),

          // Summary Card
          _buildSummaryCard(
            totalDebits: totalDebits,
            totalCredits: totalCredits,
            totalPayments: totalPayments,
            currentBalance: customer.outstandingBalance,
          ),
          pw.SizedBox(height: 20),

          // Ledger Table
          _buildLedgerTable(ledgerEntries),
          pw.SizedBox(height: 20),

          // Closing Balance
          _buildClosingBalance(customer.outstandingBalance),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildStatementHeader({
    required String businessName,
    required CustomerModel customer,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Customer Statement',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Statement Date',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                dateFormat.format(DateTime.now()),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              if (startDate != null && endDate != null) ...[
                pw.Text(
                  'Period',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerDetailsCard(CustomerModel customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Customer Details',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                if (customer.phone != null) pw.Text('Phone: ${customer.phone}'),
                if (customer.email != null) pw.Text('Email: ${customer.email}'),
                if (customer.address != null) pw.Text('Address: ${customer.address}'),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Customer ID', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text(customer.id.substring(0, 8), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Member Since', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text(dateFormat.format(customer.createdAt)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard({
    required double totalDebits,
    required double totalCredits,
    required double totalPayments,
    required double currentBalance,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Credits', totalCredits + totalDebits, PdfColors.red),
          _buildSummaryItem('Total Payments', totalPayments, PdfColors.green700),
          _buildSummaryItem('Current Balance', currentBalance, currentBalance > 0 ? PdfColors.orange : PdfColors.green700),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildLedgerTable(List<LedgerModel> entries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction History',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Debit', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Credit', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Balance', isHeader: true, align: pw.TextAlign.right),
              ],
            ),
            // Data rows
            ...entries.map((entry) {
              final isPayment = entry.isPayment;
              return pw.TableRow(
                children: [
                  _buildTableCell(dateFormat.format(entry.transactionDate)),
                  _buildTableCell(entry.description),
                  _buildTableCell(
                    !isPayment ? currencyFormat.format(entry.amount) : '-',
                    align: pw.TextAlign.right,
                    color: PdfColors.red,
                  ),
                  _buildTableCell(
                    isPayment ? currencyFormat.format(entry.amount) : '-',
                    align: pw.TextAlign.right,
                    color: PdfColors.green700,
                  ),
                  _buildTableCell(
                    currencyFormat.format(entry.balanceAfter),
                    align: pw.TextAlign.right,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 10 : 9,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _buildClosingBalance(double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: balance > 0 ? PdfColors.orange50 : PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: balance > 0 ? PdfColors.orange : PdfColors.green700,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Closing Balance',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.Text(
            currencyFormat.format(balance),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color: balance > 0 ? PdfColors.orange : PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${dateFormat.format(generatedAt)} at ${DateFormat('HH:mm').format(generatedAt)}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // Generate Sale Invoice PDF
  Future<Uint8List> generateSaleInvoice({
    required SaleModel sale,
    String? businessName,
    String? businessPhone,
    String? businessAddress,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            _buildInvoiceHeader(
              businessName: businessName ?? 'Smart POS',
              businessPhone: businessPhone,
              businessAddress: businessAddress,
              invoiceNumber: sale.invoiceNumber,
              saleDate: sale.saleDate,
            ),
            pw.SizedBox(height: 30),

            // Customer Info
            _buildInvoiceCustomerInfo(sale),
            pw.SizedBox(height: 20),

            // Items Table
            _buildInvoiceItemsTable(sale),
            pw.SizedBox(height: 20),

            // Totals
            _buildInvoiceTotals(sale),
            pw.SizedBox(height: 30),

            // Payment Info
            _buildPaymentInfo(sale),

            pw.Spacer(),

            // Footer
            _buildInvoiceFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInvoiceHeader({
    required String businessName,
    String? businessPhone,
    String? businessAddress,
    required String invoiceNumber,
    required DateTime saleDate,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              businessName,
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            if (businessPhone != null) pw.Text(businessPhone, style: const pw.TextStyle(fontSize: 10)),
            if (businessAddress != null)
              pw.Container(
                width: 200,
                child: pw.Text(businessAddress, style: const pw.TextStyle(fontSize: 10)),
              ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue900,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Invoice #', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Text(invoiceNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Date', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Text(dateFormat.format(saleDate)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceCustomerInfo(SaleModel sale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text('Bill To: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(sale.customerName ?? 'Walk-in Customer'),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceItemsTable(SaleModel sale) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...sale.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(item.productName),
              _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
              _buildTableCell(currencyFormat.format(item.unitPrice), align: pw.TextAlign.right),
              _buildTableCell(currencyFormat.format(item.totalPrice), align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildInvoiceTotals(SaleModel sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildTotalRow('Subtotal', sale.subtotal),
        if (sale.discountAmount > 0) _buildTotalRow('Discount', -sale.discountAmount, isNegative: true),
        if (sale.taxAmount > 0) _buildTotalRow('Tax (${sale.taxPercent}%)', sale.taxAmount),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 100,
                child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.Container(
                width: 100,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  currencyFormat.format(sale.totalAmount),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 100,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Container(
            width: 100,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '${isNegative ? '-' : ''}${currencyFormat.format(amount.abs())}',
              style: pw.TextStyle(fontSize: 10, color: isNegative ? PdfColors.green700 : null),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentInfo(SaleModel sale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPaymentItem('Payment Method', sale.paymentMethod.toUpperCase()),
          _buildPaymentItem('Paid', currencyFormat.format(sale.paidAmount)),
          _buildPaymentItem(
            'Due',
            currencyFormat.format(sale.dueAmount),
            color: sale.dueAmount > 0 ? PdfColors.red : PdfColors.green700,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceFooter() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text('Thank you for your business!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated by Smart POS',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // Print PDF
  Future<void> printPDF(Uint8List pdfData, {String? jobName}) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: jobName ?? 'Smart POS Document',
    );
  }

  // Share PDF
  Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: fileName,
    );
  }

  // Save PDF to device
  Future<String?> savePDF(Uint8List pdfData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfData);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  // Generate Inventory Logs PDF Report
  Future<Uint8List> generateInventoryLogReport({
    required List<StockHistoryModel> logs,
    required DateTime reportDate,
    String? filterType,
    String? businessName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Calculate summary
    int totalStockIn = 0;
    int totalStockOut = 0;
    int totalSales = 0;
    int totalReturns = 0;
    int totalAdjustments = 0;

    for (var log in logs) {
      if (log.isStockIn) {
        totalStockIn += log.quantityChange.abs();
      } else if (log.isStockOut) {
        totalStockOut += log.quantityChange.abs();
      } else if (log.isSale) {
        totalSales += log.quantityChange.abs();
      } else if (log.isReturn) {
        totalReturns += log.quantityChange.abs();
      } else if (log.isAdjustment) {
        totalAdjustments += log.quantityChange.abs();
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildInventoryReportHeader(
          businessName: businessName ?? 'Smart POS',
          reportDate: reportDate,
          filterType: filterType,
        ),
        footer: (context) => _buildPageFooter(context, now),
        build: (context) => [
          // Summary Card
          _buildInventorySummaryCard(
            totalStockIn: totalStockIn,
            totalStockOut: totalStockOut,
            totalSales: totalSales,
            totalReturns: totalReturns,
            totalAdjustments: totalAdjustments,
            totalLogs: logs.length,
          ),
          pw.SizedBox(height: 20),

          // Logs Table
          _buildInventoryLogsTable(logs),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInventoryReportHeader({
    required String businessName,
    required DateTime reportDate,
    String? filterType,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Inventory Logs Report',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Report Date',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                dateFormat.format(reportDate),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              if (filterType != null && filterType != 'All') ...[
                pw.Text(
                  'Filter',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  filterType,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInventorySummaryCard({
    required int totalStockIn,
    required int totalStockOut,
    required int totalSales,
    required int totalReturns,
    required int totalAdjustments,
    required int totalLogs,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildInventorySummaryItem('Total Logs', totalLogs.toString(), PdfColors.grey800),
              _buildInventorySummaryItem('Stock In', '+$totalStockIn', PdfColors.green700),
              _buildInventorySummaryItem('Stock Out', '-$totalStockOut', PdfColors.orange),
              _buildInventorySummaryItem('Sales', '-$totalSales', PdfColors.blue700),
              _buildInventorySummaryItem('Returns', '+$totalReturns', PdfColors.purple),
              _buildInventorySummaryItem('Adjustments', '$totalAdjustments', PdfColors.grey600),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInventorySummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInventoryLogsTable(List<StockHistoryModel> logs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inventory Activity Log',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green100),
              children: [
                _buildTableCell('Date/Time', isHeader: true),
                _buildTableCell('Product', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                _buildTableCell('Stock', isHeader: true, align: pw.TextAlign.center),
                _buildTableCell('Notes', isHeader: true),
              ],
            ),
            // Data rows
            ...logs.map((log) {
              final isPositive = log.quantityChange > 0;
              return pw.TableRow(
                children: [
                  _buildTableCell(DateFormat('dd-MMM HH:mm').format(log.operationDate)),
                  _buildTableCell(log.productName ?? 'N/A'),
                  _buildTableCell(
                    _getOperationLabel(log.operationType),
                    color: isPositive ? PdfColors.green700 : PdfColors.red,
                  ),
                  _buildTableCell(
                    '${isPositive ? '+' : ''}${log.quantityChange}',
                    align: pw.TextAlign.center,
                    color: isPositive ? PdfColors.green700 : PdfColors.red,
                  ),
                  _buildTableCell(
                    '${log.quantityAfter}',
                    align: pw.TextAlign.center,
                  ),
                  _buildTableCell(log.notes ?? '-'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  String _getOperationLabel(String type) {
    switch (type) {
      case AppConstants.stockIn:
        return 'Purchase';
      case AppConstants.stockOut:
        return 'Stock Out';
      case AppConstants.stockAdjust:
        return 'Adjustment';
      case AppConstants.stockSale:
        return 'Sale';
      case AppConstants.stockReturn:
        return 'Return';
      default:
        return type;
    }
  }
}

