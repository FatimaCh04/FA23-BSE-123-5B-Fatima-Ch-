import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/sale_model.dart';

class PrinterDevice {
  final String address;
  final String name;
  final int type;
  bool isConnected;

  PrinterDevice({
    required this.address,
    required this.name,
    this.type = 0,
    this.isConnected = false,
  });

  BluetoothDevice toBluetoothDevice() => BluetoothDevice(name, address);

  Map<String, dynamic> toJson() => {
    'address': address,
    'name': name,
    'type': type,
  };

  factory PrinterDevice.fromJson(Map<String, dynamic> json) => PrinterDevice(
    address: json['address'] ?? '',
    name: json['name'] ?? 'Unknown',
    type: json['type'] ?? 0,
  );

  factory PrinterDevice.fromBluetoothDevice(BluetoothDevice device) => PrinterDevice(
    address: device.address ?? '',
    name: device.name ?? 'Unknown Device',
    type: device.type ?? 0,
  );
}

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  
  List<PrinterDevice> _availableDevices = [];
  PrinterDevice? _connectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  String _status = 'Not connected';
  bool _bluetoothEnabled = false;

  List<PrinterDevice> get availableDevices => _availableDevices;
  PrinterDevice? get connectedPrinter => _connectedPrinter;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isPrinting => _isPrinting;
  bool get isConnected => _connectedPrinter != null && _connectedPrinter!.isConnected;
  String get status => _status;
  bool get bluetoothEnabled => _bluetoothEnabled;

  Future<void> initialize() async {
    await _loadSavedPrinter();
    await _checkBluetoothState();
  }

  Future<void> _checkBluetoothState() async {
    try {
      _bluetoothEnabled = await _bluetooth.isOn ?? false;
      
      // Listen for connection state changes
      _bluetooth.onStateChanged().listen((state) {
        switch (state) {
          case BlueThermalPrinter.CONNECTED:
            _connectedPrinter?.isConnected = true;
            _status = 'Connected to ${_connectedPrinter?.name ?? "printer"}';
            break;
          case BlueThermalPrinter.DISCONNECTED:
            _connectedPrinter?.isConnected = false;
            _status = 'Disconnected';
            break;
          case BlueThermalPrinter.STATE_TURNING_OFF:
            _bluetoothEnabled = false;
            _status = 'Bluetooth turning off';
            break;
          case BlueThermalPrinter.STATE_OFF:
            _bluetoothEnabled = false;
            _connectedPrinter?.isConnected = false;
            _status = 'Bluetooth is off';
            break;
          case BlueThermalPrinter.STATE_ON:
            _bluetoothEnabled = true;
            _status = 'Bluetooth is on';
            break;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error checking Bluetooth state: $e');
    }
  }

  Future<void> _loadSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final printerAddress = prefs.getString('saved_printer_address');
      final printerName = prefs.getString('saved_printer_name');
      
      if (printerAddress != null && printerName != null) {
        _connectedPrinter = PrinterDevice(
          address: printerAddress,
          name: printerName,
          isConnected: false,
        );
        _status = 'Saved: $printerName (not connected)';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved printer: $e');
    }
  }

  Future<void> _savePrinter(PrinterDevice printer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_printer_address', printer.address);
      await prefs.setString('saved_printer_name', printer.name);
    } catch (e) {
      debugPrint('Error saving printer: $e');
    }
  }

  Future<void> _clearSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_printer_address');
      await prefs.remove('saved_printer_name');
    } catch (e) {
      debugPrint('Error clearing saved printer: $e');
    }
  }

  Future<bool> checkBluetoothEnabled() async {
    try {
      _bluetoothEnabled = await _bluetooth.isOn ?? false;
      return _bluetoothEnabled;
    } catch (e) {
      return false;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    _isScanning = true;
    _availableDevices.clear();
    _status = 'Scanning...';
    notifyListeners();

    try {
      // Check if Bluetooth is on
      final isOn = await checkBluetoothEnabled();
      if (!isOn) {
        _status = 'Please enable Bluetooth';
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Get bonded (paired) devices
      final bondedDevices = await _bluetooth.getBondedDevices();
      
      for (final device in bondedDevices) {
        _availableDevices.add(PrinterDevice.fromBluetoothDevice(device));
      }
      
      _isScanning = false;
      _status = _availableDevices.isEmpty 
          ? 'No devices found' 
          : '${_availableDevices.length} devices found';
      notifyListeners();
      
    } catch (e) {
      _status = 'Scan error: $e';
      debugPrint('Scan error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connectToPrinter(PrinterDevice printer) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    _status = 'Connecting to ${printer.name}...';
    notifyListeners();

    try {
      // Check if already connected
      final connected = await _bluetooth.isConnected ?? false;
      if (connected) {
        await _bluetooth.disconnect();
      }

      // Connect to the device
      await _bluetooth.connect(printer.toBluetoothDevice());
      
      _connectedPrinter = PrinterDevice(
        address: printer.address,
        name: printer.name,
        type: printer.type,
        isConnected: true,
      );
      
      await _savePrinter(_connectedPrinter!);
      
      _status = 'Connected to ${printer.name}';
      _isConnecting = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = 'Connection failed: $e';
      debugPrint('Connection error: $e');
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
      _connectedPrinter?.isConnected = false;
      _status = 'Disconnected';
      notifyListeners();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  Future<void> forgetPrinter() async {
    await disconnect();
    await _clearSavedPrinter();
    _connectedPrinter = null;
    _status = 'Not connected';
    notifyListeners();
  }

  // Print receipt
  Future<bool> printReceipt(SaleModel sale, {String? businessName, String? address, String? phone}) async {
    final connected = await _bluetooth.isConnected ?? false;
    if (!connected) {
      _status = 'Printer not connected';
      notifyListeners();
      return false;
    }

    _isPrinting = true;
    _status = 'Printing...';
    notifyListeners();

    try {
      // Header
      _bluetooth.printNewLine();
      _bluetooth.printCustom(businessName ?? 'Smart POS', 3, 1);
      
      if (address != null) {
        _bluetooth.printCustom(address, 1, 1);
      }
      
      if (phone != null) {
        _bluetooth.printCustom('Tel: $phone', 1, 1);
      }

      _bluetooth.printCustom('--------------------------------', 1, 1);

      // Invoice details
      _bluetooth.printLeftRight('Invoice:', sale.invoiceNumber, 1);
      _bluetooth.printLeftRight('Date:', _formatDate(sale.saleDate), 1);
      _bluetooth.printLeftRight('Customer:', sale.customerName ?? 'Walk-in', 1);
      
      _bluetooth.printCustom('--------------------------------', 1, 1);

      // Items header
      _bluetooth.printCustom('Item          Qty     Price', 1, 0);
      _bluetooth.printCustom('--------------------------------', 1, 1);

      // Items
      for (final item in sale.items) {
        final name = item.productName.length > 14 
            ? item.productName.substring(0, 14) 
            : item.productName.padRight(14);
        final qty = '${item.quantity}'.padLeft(3);
        final price = '${item.totalPrice.toStringAsFixed(0)}'.padLeft(8);
        _bluetooth.printCustom('$name$qty$price', 1, 0);
      }

      _bluetooth.printCustom('--------------------------------', 1, 1);

      // Totals
      _bluetooth.printLeftRight('Subtotal:', 'PKR ${sale.subtotal.toStringAsFixed(0)}', 1);

      if (sale.discountAmount > 0) {
        _bluetooth.printLeftRight('Discount:', '-PKR ${sale.discountAmount.toStringAsFixed(0)}', 1);
      }

      if (sale.taxAmount > 0) {
        _bluetooth.printLeftRight('Tax:', 'PKR ${sale.taxAmount.toStringAsFixed(0)}', 1);
      }

      _bluetooth.printCustom('================================', 1, 1);
      _bluetooth.printLeftRight('TOTAL:', 'PKR ${sale.totalAmount.toStringAsFixed(0)}', 2);
      _bluetooth.printLeftRight('Paid:', 'PKR ${sale.paidAmount.toStringAsFixed(0)}', 1);

      if (sale.dueAmount > 0) {
        _bluetooth.printLeftRight('Due:', 'PKR ${sale.dueAmount.toStringAsFixed(0)}', 1);
      }

      _bluetooth.printCustom('--------------------------------', 1, 1);

      // Footer
      _bluetooth.printCustom('Thank you for your purchase!', 1, 1);
      _bluetooth.printCustom('Powered by Smart POS', 0, 1);

      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      
      _isPrinting = false;
      _status = 'Print complete';
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Print failed: $e';
      debugPrint('Print error: $e');
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  // Print test page
  Future<bool> printTestPage() async {
    final connected = await _bluetooth.isConnected ?? false;
    if (!connected) {
      _status = 'Printer not connected';
      notifyListeners();
      return false;
    }

    _isPrinting = true;
    _status = 'Printing test page...';
    notifyListeners();

    try {
      _bluetooth.printNewLine();
      _bluetooth.printCustom('PRINTER TEST', 3, 1);
      _bluetooth.printCustom('================================', 1, 1);
      _bluetooth.printCustom('Smart POS Printer Test', 1, 1);
      _bluetooth.printLeftRight('Connection:', 'OK', 1);
      _bluetooth.printLeftRight('Date:', _formatDate(DateTime.now()), 1);
      _bluetooth.printCustom('================================', 1, 1);
      _bluetooth.printCustom('If you can read this,', 1, 1);
      _bluetooth.printCustom('your printer is working!', 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      
      _isPrinting = false;
      _status = 'Test print complete';
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Test print failed: $e';
      debugPrint('Test print error: $e');
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
