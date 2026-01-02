import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/models/stock_history_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_drawer.dart';

class InventoryLogsScreen extends StatefulWidget {
  const InventoryLogsScreen({super.key});

  @override
  State<InventoryLogsScreen> createState() => _InventoryLogsScreenState();
}

class _InventoryLogsScreenState extends State<InventoryLogsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';
  List<StockHistoryModel> _logs = [];
  bool _isLoading = true;

  final List<String> _filterOptions = [
    'All',
    'Purchase',
    'Sale',
    'Stock In',
    'Stock Out',
    'Adjustment',
    'Return',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<ProductProvider>();
    final allHistory = <StockHistoryModel>[];
    
    for (final product in provider.allProducts) {
      final history = await provider.getStockHistory(product.id);
      allHistory.addAll(history);
    }
    
    // Filter by selected date
    final filteredByDate = allHistory.where((log) {
      final logDate = DateTime(
        log.operationDate.year,
        log.operationDate.month,
        log.operationDate.day,
      );
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      return logDate == selectedDateOnly;
    }).toList();
    
    // Filter by type
    List<StockHistoryModel> filteredLogs;
    if (_selectedFilter == 'All') {
      filteredLogs = filteredByDate;
    } else {
      final filterType = _getFilterType(_selectedFilter);
      filteredLogs = filteredByDate.where((log) => 
        log.operationType.toLowerCase() == filterType.toLowerCase()
      ).toList();
    }
    
    filteredLogs.sort((a, b) => b.operationDate.compareTo(a.operationDate));
    
    setState(() {
      _logs = filteredLogs;
      _isLoading = false;
    });
  }

  String _getFilterType(String filter) {
    switch (filter) {
      case 'Purchase':
        return AppConstants.stockIn;
      case 'Sale':
        return AppConstants.stockSale;
      case 'Stock In':
        return AppConstants.stockIn;
      case 'Stock Out':
        return AppConstants.stockOut;
      case 'Adjustment':
        return AppConstants.stockAdjust;
      case 'Return':
        return AppConstants.stockReturn;
      default:
        return '';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      setState(() => _selectedDate = picked);
      _loadLogs();
    }
  }

  Future<void> _exportPDF() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No logs to export'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final pdfService = PDFService();
      
      // Generate PDF
      final pdfData = await pdfService.generateInventoryLogReport(
        logs: _logs,
        reportDate: _selectedDate,
        filterType: _selectedFilter,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Generate filename with date
      final fileName = 'Inventory_Logs_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';

      // Share the PDF
      await pdfService.sharePDF(pdfData, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No logs to export'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventory Logs'];

      // Header row
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Product'),
        TextCellValue('Operation'),
        TextCellValue('Qty Before'),
        TextCellValue('Change'),
        TextCellValue('Qty After'),
        TextCellValue('Vendor'),
        TextCellValue('Notes'),
      ]);

      // Style header
      for (int i = 0; i < 9; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0D4D47'),
          fontColorHex: ExcelColor.white,
        );
      }

      // Data rows
      for (var log in _logs) {
        sheet.appendRow([
          TextCellValue(DateFormat('dd/MM/yyyy').format(log.operationDate)),
          TextCellValue(DateFormat('hh:mm a').format(log.operationDate)),
          TextCellValue(log.productName ?? '-'),
          TextCellValue(log.operationType.toUpperCase()),
          IntCellValue(log.quantityBefore),
          IntCellValue(log.quantityChange),
          IntCellValue(log.quantityAfter),
          TextCellValue(log.vendorName ?? '-'),
          TextCellValue(log.notes ?? '-'),
        ]);
      }

      // Auto-fit columns
      for (int i = 0; i < 9; i++) {
        sheet.setColumnWidth(i, 15);
      }

      // Remove default sheet
      excel.delete('Sheet1');

      // Save file
      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to generate Excel');

      final directory = await getExternalStorageDirectory();
      final fileName = 'Inventory_Logs_${DateFormat('yyyyMMdd').format(_selectedDate)}.xlsx';
      final filePath = '${directory?.path ?? '/storage/emulated/0/Download'}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Open file
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
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting Excel: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
            Text('Export Options', style: AppTheme.titleLarge),
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
              subtitle: const Text('Share or print inventory logs'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Logs', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 3),
      body: Column(
        children: [
          // Date Picker
          Container(
            margin: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              title: Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
                style: AppTheme.titleMedium,
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectDate,
            ),
          ),

          // Filter Dropdown
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: AppTheme.cardDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: _filterOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: AppTheme.bodyMedium),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedFilter = newValue);
                    _loadLogs();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Export Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showExportOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.file_download),
                label: const Text('Export Inventory Logs'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return _buildLogCard(_logs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(StockHistoryModel log) {
    final isPositive = log.quantityChange > 0;
    final typeLabel = _getOperationLabel(log.operationType);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel.toUpperCase(),
                  style: AppTheme.labelMedium.copyWith(
                    color: isPositive 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('dd-MMM, hh:mm a').format(log.operationDate),
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            log.productName ?? 'Product',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Qty: ${log.quantityChange.abs()} ${isPositive ? '↑' : '↓'}',
                style: AppTheme.bodyMedium.copyWith(
                  color: isPositive 
                      ? AppTheme.successColor 
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Stock: ${log.quantityAfter}',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.notes!,
              style: AppTheme.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
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
            'No logs found',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No inventory activities on this date',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

