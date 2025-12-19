import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = false;
  bool _isInitialized = false;
  List<ConnectivityResult> _connectionStatus = [];

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check initial connectivity
    _connectionStatus = await _connectivity.checkConnectivity();
    _updateOnlineStatus();
    
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _connectionStatus = result;
      _updateOnlineStatus();
      notifyListeners();
    });
    
    _isInitialized = true;
  }

  void _updateOnlineStatus() {
    final wasOnline = _isOnline;
    _isOnline = !_connectionStatus.contains(ConnectivityResult.none);
    
    if (!wasOnline && _isOnline) {
      // Connection restored - trigger sync
      debugPrint('Connection restored! Triggering sync...');
    } else if (wasOnline && !_isOnline) {
      // Connection lost
      debugPrint('Connection lost! Switching to offline mode...');
    }
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _connectionStatus = result;
    _updateOnlineStatus();
    return _isOnline;
  }

  String getConnectionType() {
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (_connectionStatus.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    } else if (_connectionStatus.contains(ConnectivityResult.bluetooth)) {
      return 'Bluetooth';
    } else {
      return 'Offline';
    }
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

