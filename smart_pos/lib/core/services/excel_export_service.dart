import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';

class ExcelExportService {
  static final ExcelExportService _instance = ExcelExportService._internal();
  factory ExcelExportService() => _instance;
  ExcelExportService._internal();

  final _dateFormat = DateFormat('dd-MM-yyyy');
  final _dateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');
  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  // Export All Sales to Excel
  Future<String?> exportSalesToExcel(List<SaleModel> sales, {String? fileName}) async {
    try {
      debugPrint('[ExcelExport] Starting export with ${sales.length} sales');
      
      if (sales.isEmpty) {
        debugPrint('[ExcelExport] No sales to export!');
        return null;
      }
      
      // Log first sale for debugging
      if (sales.isNotEmpty) {
        final first = sales.first;
        debugPrint('[ExcelExport] First sale: ${first.invoiceNumber}, Total: ${first.totalAmount}, Items: ${first.totalItems}');
      }
      
      final excel = Excel.createExcel();
      
      // Remove default sheet and create Sales sheet
      excel.delete('Sheet1');
      final sheet = excel['Sales Report'];
      
      // Header style
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#00796B'),
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
      );
      
      // Add headers
      final headers = [
        'Sr. No',
        'Invoice #',
        'Date',
        'Time',
        'Customer',
        'Items',
        'Subtotal',
        'Discount',
        'Tax',
        'Total',
        'Paid',
        'Due',
        'Payment Method',
        'Status',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      
      // Add data rows
      for (int i = 0; i < sales.length; i++) {
        final sale = sales[i];
        final row = i + 1;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(sale.invoiceNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(_dateFormat.format(sale.saleDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(DateFormat('HH:mm').format(sale.saleDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(sale.customerName ?? 'Walk-in');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = IntCellValue(sale.totalItems);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(sale.subtotal);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(sale.discountAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = DoubleCellValue(sale.taxAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = DoubleCellValue(sale.totalAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value = DoubleCellValue(sale.paidAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value = DoubleCellValue(sale.dueAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value = TextCellValue(sale.paymentMethod.toUpperCase());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value = TextCellValue(sale.isPaid ? 'PAID' : 'PENDING');
      }
      
      // Add summary row
      final summaryRow = sales.length + 2;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow)).value = TextCellValue('TOTAL:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow)).cellStyle = CellStyle(bold: true);
      
      final totalSales = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
      final totalPaid = sales.fold(0.0, (sum, s) => sum + s.paidAmount);
      final totalDue = sales.fold(0.0, (sum, s) => sum + s.dueAmount);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: summaryRow)).value = DoubleCellValue(totalSales);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: summaryRow)).cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: summaryRow)).value = DoubleCellValue(totalPaid);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: summaryRow)).cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: summaryRow)).value = DoubleCellValue(totalDue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: summaryRow)).cellStyle = CellStyle(bold: true);
      
      // Set column widths
      sheet.setColumnWidth(0, 8);   // Sr. No
      sheet.setColumnWidth(1, 20);  // Invoice
      sheet.setColumnWidth(2, 12);  // Date
      sheet.setColumnWidth(3, 8);   // Time
      sheet.setColumnWidth(4, 20);  // Customer
      sheet.setColumnWidth(5, 8);   // Items
      sheet.setColumnWidth(6, 12);  // Subtotal
      sheet.setColumnWidth(7, 10);  // Discount
      sheet.setColumnWidth(8, 10);  // Tax
      sheet.setColumnWidth(9, 12);  // Total
      sheet.setColumnWidth(10, 12); // Paid
      sheet.setColumnWidth(11, 12); // Due
      sheet.setColumnWidth(12, 15); // Payment Method
      sheet.setColumnWidth(13, 10); // Status
      
      // Save file - try external storage first, then documents
      Directory? directory;
      try {
        directory = await getExternalStorageDirectory();
      } catch (e) {
        debugPrint('[ExcelExport] External storage not available: $e');
      }
      directory ??= await getApplicationDocumentsDirectory();
      
      final name = fileName ?? 'Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      final filePath = '${directory.path}/$name.xlsx';
      
      debugPrint('[ExcelExport] Saving to: $filePath');
      debugPrint('[ExcelExport] Added ${sales.length} rows to Excel');
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        debugPrint('[ExcelExport] File bytes: ${fileBytes.length}');
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        debugPrint('[ExcelExport] File saved successfully');
        return filePath;
      }
      debugPrint('[ExcelExport] fileBytes is null!');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[ExcelExport] Error: $e');
      debugPrint('[ExcelExport] Stack: $stackTrace');
      return null;
    }
  }

  // Export Sales with Items Detail
  Future<String?> exportSalesWithItems(List<SaleModel> sales, {String? fileName}) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      
      // Sales Summary Sheet
      final summarySheet = excel['Sales Summary'];
      _addSalesSummarySheet(summarySheet, sales);
      
      // Sales Items Detail Sheet
      final itemsSheet = excel['Sales Items'];
      _addSalesItemsSheet(itemsSheet, sales);
      
      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final name = fileName ?? 'Sales_Detail_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      final filePath = '${directory.path}/$name.xlsx';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      print('Excel export error: $e');
      return null;
    }
  }

  void _addSalesSummarySheet(Sheet sheet, List<SaleModel> sales) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#00796B'),
      fontColorHex: ExcelColor.white,
    );
    
    final headers = ['Invoice #', 'Date', 'Customer', 'Total Items', 'Total Amount', 'Paid', 'Due', 'Status'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    
    for (int i = 0; i < sales.length; i++) {
      final sale = sales[i];
      final row = i + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(sale.invoiceNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(_dateTimeFormat.format(sale.saleDate));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(sale.customerName ?? 'Walk-in');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = IntCellValue(sale.totalItems);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(sale.totalAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(sale.paidAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(sale.dueAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(sale.isPaid ? 'PAID' : 'PENDING');
    }
  }

  void _addSalesItemsSheet(Sheet sheet, List<SaleModel> sales) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#00796B'),
      fontColorHex: ExcelColor.white,
    );
    
    final headers = ['Invoice #', 'Date', 'Product', 'SKU', 'Qty', 'Unit Price', 'Discount', 'Total'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    
    int row = 1;
    for (final sale in sales) {
      for (final item in sale.items) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(sale.invoiceNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(_dateFormat.format(sale.saleDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(item.productName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(item.sku ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = IntCellValue(item.quantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(item.unitPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(item.discountAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(item.totalPrice);
        row++;
      }
    }
  }

  // Export Products Inventory to Excel
  Future<String?> exportProductsToExcel(List<ProductModel> products, {String? fileName}) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Products Inventory'];
      
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#00796B'),
        fontColorHex: ExcelColor.white,
      );
      
      final headers = ['Sr. No', 'SKU', 'Product Name', 'Category', 'Cost Price', 'Sale Price', 'Stock', 'Low Stock Alert', 'Status'];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final row = i + 1;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(product.sku);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(product.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(product.categoryName ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(product.costPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(product.salePrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = IntCellValue(product.quantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = IntCellValue(product.lowStockThreshold);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = TextCellValue(product.isActive ? 'Active' : 'Inactive');
      }
      
      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final name = fileName ?? 'Products_Inventory_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      final filePath = '${directory.path}/$name.xlsx';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      print('Excel export error: $e');
      return null;
    }
  }

  // Export Customers to Excel
  Future<String?> exportCustomersToExcel(List<CustomerModel> customers, {String? fileName}) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Customers'];
      
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#00796B'),
        fontColorHex: ExcelColor.white,
      );
      
      final headers = ['Sr. No', 'Name', 'Phone', 'Email', 'Address', 'Total Purchases', 'Outstanding Balance', 'Customer Since'];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      
      for (int i = 0; i < customers.length; i++) {
        final customer = customers[i];
        final row = i + 1;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(customer.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(customer.phone ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(customer.email ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(customer.address ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(customer.totalPurchases);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(customer.outstandingBalance);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(_dateFormat.format(customer.createdAt));
      }
      
      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final name = fileName ?? 'Customers_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      final filePath = '${directory.path}/$name.xlsx';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      print('Excel export error: $e');
      return null;
    }
  }

  // Share Excel file
  Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Sales Report - Mobile Shop POS');
    } catch (e) {
      print('Share error: $e');
    }
  }

  // Open Excel file
  Future<void> openExcelFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('Open file error: $e');
    }
  }
}

