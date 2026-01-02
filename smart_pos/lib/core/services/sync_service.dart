import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  FirebaseFirestore? _firestore;
  bool _firebaseAvailable = false;
  
  FirebaseFirestore? get firestore {
    if (!_firebaseAvailable) {
      try {
        _firestore ??= FirebaseFirestore.instance;
        _firebaseAvailable = true;
      } catch (e) {
        debugPrint('Firebase not available: $e');
        return null;
      }
    }
    return _firestore;
  }
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingSyncCount = 0;
  String _syncStatus = 'idle';
  List<String> _syncErrors = [];

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSyncCount => _pendingSyncCount;
  String get syncStatus => _syncStatus;
  List<String> get syncErrors => _syncErrors;

  Future<void> initialize() async {
    await _loadLastSyncTime();
    await _updatePendingCount();
    
    // Listen for connectivity changes
    _connectivityService.addListener(_onConnectivityChanged);
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(AppConstants.lastSyncKey);
    if (lastSync != null) {
      _lastSyncTime = DateTime.parse(lastSync);
    }
  }

  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = DateTime.now();
    await prefs.setString(AppConstants.lastSyncKey, _lastSyncTime!.toIso8601String());
  }

  Future<void> _updatePendingCount() async {
    int count = 0;
    
    final tables = [
      AppConstants.categoriesTable,
      AppConstants.productsTable,
      AppConstants.customersTable,
      AppConstants.salesTable,
      AppConstants.ledgerTable,
      AppConstants.stockHistoryTable,
    ];

    for (final table in tables) {
      final records = await _db.getPendingSyncRecords(table);
      count += records.length;
    }

    _pendingSyncCount = count;
    notifyListeners();
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && _pendingSyncCount > 0) {
      syncAll();
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing || !_connectivityService.isOnline) return;
    
    // Check if Firebase is available
    if (firestore == null) {
      debugPrint('Sync skipped: Firebase not available');
      return;
    }

    _isSyncing = true;
    _syncStatus = 'syncing';
    _syncErrors = [];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Sync in order of dependencies
      await _syncCategories(userId);
      await _syncProducts(userId);
      await _syncCustomers(userId);
      await _syncSales(userId);
      await _syncLedger(userId);
      await _syncStockHistory(userId);

      // Download remote changes
      await _downloadRemoteChanges(userId);

      await _saveLastSyncTime();
      await _updatePendingCount();

      _syncStatus = 'completed';
    } catch (e) {
      _syncErrors.add(e.toString());
      _syncStatus = 'error';
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncCategories(String userId) async {
    final records = await _db.getPendingSyncRecords(AppConstants.categoriesTable);
    
    for (final record in records) {
      try {
        await firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.categoriesCollection)
            .doc(record['id'])
            .set(record, SetOptions(merge: true));
        
        await _db.markAsSynced(AppConstants.categoriesTable, record['id']);
      } catch (e) {
        _syncErrors.add('Category sync error: ${record['name']} - $e');
      }
    }
  }

  Future<void> _syncProducts(String userId) async {
    final records = await _db.getPendingSyncRecords(AppConstants.productsTable);
    
    for (final record in records) {
      try {
        await firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.productsCollection)
            .doc(record['id'])
            .set(record, SetOptions(merge: true));
        
        await _db.markAsSynced(AppConstants.productsTable, record['id']);
      } catch (e) {
        _syncErrors.add('Product sync error: ${record['name']} - $e');
      }
    }
  }

  Future<void> _syncCustomers(String userId) async {
    final records = await _db.getPendingSyncRecords(AppConstants.customersTable);
    
    for (final record in records) {
      try {
        await firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.customersCollection)
            .doc(record['id'])
            .set(record, SetOptions(merge: true));
        
        await _db.markAsSynced(AppConstants.customersTable, record['id']);
      } catch (e) {
        _syncErrors.add('Customer sync error: ${record['name']} - $e');
      }
    }
  }

  Future<void> _syncSales(String userId) async {
    final records = await _db.getPendingSyncRecords(AppConstants.salesTable);
    
    for (final record in records) {
      try {
        // Get sale items
        final items = await _db.query(
          AppConstants.saleItemsTable,
          where: 'sale_id = ?',
          whereArgs: [record['id']],
        );
        
        record['items'] = items;
        
        await firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.salesCollection)
            .doc(record['id'])
            .set(record, SetOptions(merge: true));
        
        await _db.markAsSynced(AppConstants.salesTable, record['id']);
      } catch (e) {
        _syncErrors.add('Sale sync error: ${record['invoice_number']} - $e');
      }
    }
  }

  Future<void> _syncLedger(String userId) async {
    final records = await _db.getPendingSyncRecords(AppConstants.ledgerTable);
    
    for (final record in records) {
      try {
        await firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.ledgerCollection)
            .doc(record['id'])
            .set(record, SetOptions(merge: true));
        
        await _db.markAsSynced(AppConstants.ledgerTable, record['id']);
      } catch (e) {
        _syncErrors.add('Ledger sync error: $e');
      }
    }
  }

  Future<void> _syncStockHistory(String userId) async {
    final records = await _db.getPendingSyncRecords(AppConstants.stockHistoryTable);
    
    for (final record in records) {
      try {
        await firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.stockHistoryCollection)
            .doc(record['id'])
            .set(record, SetOptions(merge: true));
        
        await _db.markAsSynced(AppConstants.stockHistoryTable, record['id']);
      } catch (e) {
        _syncErrors.add('Stock history sync error: $e');
      }
    }
  }

  Future<void> _downloadRemoteChanges(String userId) async {
    // Get last sync time or default to 30 days ago for better data recovery
    final lastSync = _lastSyncTime ?? DateTime.now().subtract(const Duration(days: 30));
    
    // Download categories
    await _downloadCollection(
      userId,
      AppConstants.categoriesCollection,
      AppConstants.categoriesTable,
      lastSync,
    );

    // Download products
    await _downloadCollection(
      userId,
      AppConstants.productsCollection,
      AppConstants.productsTable,
      lastSync,
    );

    // Download customers
    await _downloadCollection(
      userId,
      AppConstants.customersCollection,
      AppConstants.customersTable,
      lastSync,
    );

    // Download sales
    await _downloadCollection(
      userId,
      AppConstants.salesCollection,
      AppConstants.salesTable,
      lastSync,
    );

    // Download ledger
    await _downloadCollection(
      userId,
      AppConstants.ledgerCollection,
      AppConstants.ledgerTable,
      lastSync,
    );

    // Download stock history
    await _downloadCollection(
      userId,
      AppConstants.stockHistoryCollection,
      AppConstants.stockHistoryTable,
      lastSync,
    );
  }

  Future<void> _downloadCollection(
    String userId,
    String collection,
    String table,
    DateTime lastSync,
  ) async {
    try {
      final snapshot = await firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(collection)
          .where('updated_at', isGreaterThan: lastSync.toIso8601String())
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['sync_status'] = AppConstants.syncCompleted;
        
        // Check if local version is newer (conflict resolution)
        final localRecords = await _db.query(
          table,
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (localRecords.isNotEmpty) {
          final localUpdatedAt = localRecords.first['updated_at'] != null 
              ? DateTime.parse(localRecords.first['updated_at'])
              : DateTime.fromMillisecondsSinceEpoch(0);
          final remoteUpdatedAt = data['updated_at'] != null 
              ? DateTime.parse(data['updated_at'])
              : DateTime.now();

          // Only update if remote is newer
          if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
            await _db.update(table, data, where: 'id = ?', whereArgs: [doc.id]);
          }
        } else {
          await _db.insert(table, data);
        }
      }
    } catch (e) {
      _syncErrors.add('Download error for $collection: $e');
    }
  }

  // Force sync specific table
  Future<void> syncTable(String tableName) async {
    if (!_connectivityService.isOnline) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);
    
    if (userId == null) return;

    switch (tableName) {
      case AppConstants.categoriesTable:
        await _syncCategories(userId);
        break;
      case AppConstants.productsTable:
        await _syncProducts(userId);
        break;
      case AppConstants.customersTable:
        await _syncCustomers(userId);
        break;
      case AppConstants.salesTable:
        await _syncSales(userId);
        break;
      case AppConstants.ledgerTable:
        await _syncLedger(userId);
        break;
      case AppConstants.stockHistoryTable:
        await _syncStockHistory(userId);
        break;
    }

    await _updatePendingCount();
    notifyListeners();
  }

  // Force full sync - upload local changes and download remote data
  Future<void> forceFullSync() async {
    if (!_connectivityService.isOnline) {
      _syncStatus = 'offline';
      notifyListeners();
      return;
    }

    await syncAll();
  }

  // Download all data from Firebase (useful on app startup or login)
  Future<void> downloadAllData() async {
    if (!_connectivityService.isOnline) return;

    _isSyncing = true;
    _syncStatus = 'downloading';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Download from the beginning of time to get all data
      final startDate = DateTime(2020, 1, 1);
      
      // Download all collections
      await _downloadCollection(userId, AppConstants.categoriesCollection, AppConstants.categoriesTable, startDate);
      await _downloadCollection(userId, AppConstants.productsCollection, AppConstants.productsTable, startDate);
      await _downloadCollection(userId, AppConstants.customersCollection, AppConstants.customersTable, startDate);
      await _downloadCollection(userId, AppConstants.salesCollection, AppConstants.salesTable, startDate);
      await _downloadCollection(userId, AppConstants.ledgerCollection, AppConstants.ledgerTable, startDate);
      await _downloadCollection(userId, AppConstants.stockHistoryCollection, AppConstants.stockHistoryTable, startDate);

      _syncStatus = 'completed';
      debugPrint('Full data download completed');
    } catch (e) {
      _syncErrors.add('Download all data error: $e');
      _syncStatus = 'error';
      debugPrint('Download all data error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}

