import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/printer_service.dart';
import '../common/custom_button.dart';

class PrinterSetupSheet extends StatefulWidget {
  const PrinterSetupSheet({super.key});

  @override
  State<PrinterSetupSheet> createState() => _PrinterSetupSheetState();
}

class _PrinterSetupSheetState extends State<PrinterSetupSheet> {
  @override
  void initState() {
    super.initState();
    // Auto-scan when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final printerService = context.read<PrinterService>();
      if (printerService.availableDevices.isEmpty && !printerService.isScanning) {
        printerService.startScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterService>(
      builder: (context, printerService, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.print,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bluetooth Printer Setup',
                            style: AppTheme.headingSmall,
                          ),
                          Text(
                            printerService.status,
                            style: AppTheme.bodySmall.copyWith(
                              color: printerService.isConnected 
                                  ? AppTheme.successColor 
                                  : AppTheme.textSecondary,
                            ),
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

              // Connected Printer Card (if connected)
              if (printerService.connectedPrinter != null)
                _buildConnectedPrinterCard(printerService),

              // Scan Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomButton(
                  text: printerService.isScanning ? 'Scanning...' : 'Scan for Devices',
                  icon: Icons.search,
                  isLoading: printerService.isScanning,
                  onPressed: printerService.isScanning 
                      ? () => printerService.stopScan()
                      : () => printerService.startScan(),
                  backgroundColor: AppTheme.successColor,
                ),
              ),

              const SizedBox(height: 20),

              // Available Devices Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Available Devices (${printerService.availableDevices.length})',
                      style: AppTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (printerService.isScanning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 4),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Showing paired and discovered devices - connect to test if it\'s a printer',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Devices List
              Expanded(
                child: printerService.availableDevices.isEmpty
                    ? _buildEmptyState(printerService)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: printerService.availableDevices.length,
                        itemBuilder: (context, index) {
                          final device = printerService.availableDevices[index];
                        final isConnected = printerService.connectedPrinter?.address == device.address && 
                                            printerService.connectedPrinter?.isConnected == true;
                          return _buildDeviceCard(device, printerService, isConnected);
                        },
                      ),
              ),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your printer is turned on and paired with your device',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectedPrinterCard(PrinterService printerService) {
    final printer = printerService.connectedPrinter!;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: printerService.isConnected 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: printerService.isConnected 
              ? AppTheme.successColor 
              : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: printerService.isConnected 
                  ? AppTheme.successColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              printerService.isConnected ? Icons.print : Icons.print_disabled,
              color: printerService.isConnected 
                  ? AppTheme.successColor 
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      printer.name,
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: printerService.isConnected 
                            ? AppTheme.successColor 
                            : AppTheme.warningColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        printerService.isConnected ? 'Connected' : 'Saved',
                        style: AppTheme.labelMedium.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  printer.address,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'test') {
                if (!printerService.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please connect to printer first')),
                  );
                  return;
                }
                final success = await printerService.printTestPage();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Test page printed!' : 'Print failed'),
                      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                }
              } else if (value == 'disconnect') {
                await printerService.disconnect();
              } else if (value == 'forget') {
                await printerService.forgetPrinter();
              } else if (value == 'connect') {
                await printerService.connectToPrinter(printer);
              }
            },
            itemBuilder: (context) => [
              if (!printerService.isConnected)
                const PopupMenuItem(
                  value: 'connect',
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_connected, size: 20),
                      SizedBox(width: 8),
                      Text('Connect'),
                    ],
                  ),
                ),
              if (printerService.isConnected)
                const PopupMenuItem(
                  value: 'test',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20),
                      SizedBox(width: 8),
                      Text('Print Test Page'),
                    ],
                  ),
                ),
              if (printerService.isConnected)
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_disabled, size: 20),
                      SizedBox(width: 8),
                      Text('Disconnect'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'forget',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Forget Printer', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(PrinterDevice device, PrinterService printerService, bool isConnected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isConnected ? AppTheme.successColor.withOpacity(0.05) : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppTheme.successColor : AppTheme.dividerColor,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bluetooth,
            color: isConnected ? AppTheme.successColor : AppTheme.primaryColor,
          ),
        ),
        title: Text(device.name, style: AppTheme.titleMedium),
        subtitle:                     Text(
                      device.address,
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
        trailing: printerService.isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isConnected
                ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                : TextButton(
                    onPressed: () async {
                      final success = await printerService.connectToPrinter(device);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connected to ${device.name}'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Connect'),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(PrinterService printerService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_searching,
              size: 48,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found.',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan for Devices" to start scanning.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the printer setup sheet
void showPrinterSetupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const PrinterSetupSheet(),
  );
}

