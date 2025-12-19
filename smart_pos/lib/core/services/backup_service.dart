import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';

class BackupService extends ChangeNotifier {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _backupStatus = 'idle';
  double _progress = 0.0;
  DateTime? _lastBackupTime;
  DateTime? _lastAutoBackupTime;

  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  String get backupStatus => _backupStatus;
  double get progress => _progress;
  DateTime? get lastBackupTime => _lastBackupTime;
  DateTime? get lastAutoBackupTime => _lastAutoBackupTime;

  Future<void> initialize() async {
    await _loadBackupTimes();
  }

  Future<void> _loadBackupTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_backup_time');
    final lastAutoBackup = prefs.getString('last_auto_backup_time');
    
    if (lastBackup != null) {
      _lastBackupTime = DateTime.parse(lastBackup);
    }
    if (lastAutoBackup != null) {
      _lastAutoBackupTime = DateTime.parse(lastAutoBackup);
    }
  }

  Future<void> _saveBackupTime(bool isAuto) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    if (isAuto) {
      _lastAutoBackupTime = now;
      await prefs.setString('last_auto_backup_time', now.toIso8601String());
    } else {
      _lastBackupTime = now;
      await prefs.setString('last_backup_time', now.toIso8601String());
    }
    notifyListeners();
  }

  // Create local backup
  Future<String?> createLocalBackup() async {
    if (_isBackingUp) return null;

    _isBackingUp = true;
    _backupStatus = 'Creating local backup...';
    _progress = 0.0;
    notifyListeners();

    try {
      final backupData = await _collectBackupData();
      _progress = 0.5;
      notifyListeners();

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('${backupDir.path}/backup_$timestamp.json');
      await backupFile.writeAsString(jsonEncode(backupData));

      _progress = 1.0;
      _backupStatus = 'Local backup completed';
      await _saveBackupTime(false);
      notifyListeners();

      return backupFile.path;
    } catch (e) {
      _backupStatus = 'Backup failed: $e';
      debugPrint('Local backup error: $e');
      return null;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // Create Google Drive backup
  Future<bool> createGoogleDriveBackup() async {
    if (_isBackingUp) return false;

    _isBackingUp = true;
    _backupStatus = 'Signing in to Google...';
    _progress = 0.0;
    notifyListeners();

    try {
      // Sign in to Google
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In cancelled');
      }

      _backupStatus = 'Preparing backup data...';
      _progress = 0.2;
      notifyListeners();

      final backupData = await _collectBackupData();
      final backupJson = jsonEncode(backupData);

      _backupStatus = 'Uploading to Google Drive...';
      _progress = 0.5;
      notifyListeners();

      // Get auth client
      final googleAuth = await account.authentication;
      final authClient = _GoogleAuthClient(googleAuth.accessToken!);
      final driveApi = drive.DriveApi(authClient);

      // Create or find Smart POS folder
      String? folderId = await _getOrCreateFolder(driveApi, 'Smart POS Backups');

      // Upload backup file
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup_$timestamp.json';

      final file = drive.File()
        ..name = fileName
        ..parents = [folderId!];

      final media = drive.Media(
        Stream.value(utf8.encode(backupJson)),
        backupJson.length,
      );

      await driveApi.files.create(file, uploadMedia: media);

      _progress = 1.0;
      _backupStatus = 'Google Drive backup completed';
      await _saveBackupTime(false);
      notifyListeners();

      return true;
    } catch (e) {
      _backupStatus = 'Google Drive backup failed: $e';
      debugPrint('Google Drive backup error: $e');
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // Get list of Google Drive backups
  Future<List<drive.File>> getGoogleDriveBackups() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return [];

      final googleAuth = await account.authentication;
      final authClient = _GoogleAuthClient(googleAuth.accessToken!);
      final driveApi = drive.DriveApi(authClient);

      final folderId = await _getOrCreateFolder(driveApi, 'Smart POS Backups');
      if (folderId == null) return [];

      final response = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType='application/json'",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );

      return response.files ?? [];
    } catch (e) {
      debugPrint('Error getting Google Drive backups: $e');
      return [];
    }
  }

  // Restore from Google Drive
  Future<bool> restoreFromGoogleDrive(String fileId) async {
    if (_isRestoring) return false;

    _isRestoring = true;
    _backupStatus = 'Downloading backup...';
    _progress = 0.0;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google Sign-In cancelled');

      final googleAuth = await account.authentication;
      final authClient = _GoogleAuthClient(googleAuth.accessToken!);
      final driveApi = drive.DriveApi(authClient);

      _progress = 0.3;
      notifyListeners();

      // Download file
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      _backupStatus = 'Restoring data...';
      _progress = 0.6;
      notifyListeners();

      await _restoreBackupData(backupData);

      _progress = 1.0;
      _backupStatus = 'Restore completed';
      notifyListeners();

      return true;
    } catch (e) {
      _backupStatus = 'Restore failed: $e';
      debugPrint('Restore error: $e');
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  // Restore from local backup
  Future<bool> restoreFromLocalBackup(String filePath) async {
    if (_isRestoring) return false;

    _isRestoring = true;
    _backupStatus = 'Reading backup file...';
    _progress = 0.0;
    notifyListeners();

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      _backupStatus = 'Restoring data...';
      _progress = 0.5;
      notifyListeners();

      await _restoreBackupData(backupData);

      _progress = 1.0;
      _backupStatus = 'Restore completed';
      notifyListeners();

      return true;
    } catch (e) {
      _backupStatus = 'Restore failed: $e';
      debugPrint('Restore error: $e');
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  // Get list of local backups
  Future<List<FileSystemEntity>> getLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files.where((f) => f.path.endsWith('.json')).toList();
    } catch (e) {
      debugPrint('Error getting local backups: $e');
      return [];
    }
  }

  // Delete local backup
  Future<bool> deleteLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting local backup: $e');
      return false;
    }
  }

  // Auto backup check
  Future<void> checkAndPerformAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final autoBackupEnabled = prefs.getBool(AppConstants.autoBackupKey) ?? true;
    
    if (!autoBackupEnabled) return;

    final interval = prefs.getInt(AppConstants.backupIntervalKey) ?? 24; // hours
    
    if (_lastAutoBackupTime == null ||
        DateTime.now().difference(_lastAutoBackupTime!).inHours >= interval) {
      await createLocalBackup();
      await _saveBackupTime(true);
    }
  }

  // Collect all data for backup
  Future<Map<String, dynamic>> _collectBackupData() async {
    final categories = await _db.query(AppConstants.categoriesTable);
    final products = await _db.query(AppConstants.productsTable);
    final customers = await _db.query(AppConstants.customersTable);
    final sales = await _db.query(AppConstants.salesTable);
    final saleItems = await _db.query(AppConstants.saleItemsTable);
    final ledger = await _db.query(AppConstants.ledgerTable);
    final stockHistory = await _db.query(AppConstants.stockHistoryTable);

    return {
      'version': '1.0.0',
      'created_at': DateTime.now().toIso8601String(),
      'data': {
        'categories': categories,
        'products': products,
        'customers': customers,
        'sales': sales,
        'sale_items': saleItems,
        'ledger': ledger,
        'stock_history': stockHistory,
      },
    };
  }

  // Restore data from backup
  Future<void> _restoreBackupData(Map<String, dynamic> backupData) async {
    final data = backupData['data'] as Map<String, dynamic>;

    // Clear existing data
    await _db.clearAllData();

    // Restore in order of dependencies
    if (data['categories'] != null) {
      for (final item in data['categories']) {
        await _db.insert(AppConstants.categoriesTable, Map<String, dynamic>.from(item));
      }
    }

    if (data['products'] != null) {
      for (final item in data['products']) {
        await _db.insert(AppConstants.productsTable, Map<String, dynamic>.from(item));
      }
    }

    if (data['customers'] != null) {
      for (final item in data['customers']) {
        await _db.insert(AppConstants.customersTable, Map<String, dynamic>.from(item));
      }
    }

    if (data['sales'] != null) {
      for (final item in data['sales']) {
        await _db.insert(AppConstants.salesTable, Map<String, dynamic>.from(item));
      }
    }

    if (data['sale_items'] != null) {
      for (final item in data['sale_items']) {
        await _db.insert(AppConstants.saleItemsTable, Map<String, dynamic>.from(item));
      }
    }

    if (data['ledger'] != null) {
      for (final item in data['ledger']) {
        await _db.insert(AppConstants.ledgerTable, Map<String, dynamic>.from(item));
      }
    }

    if (data['stock_history'] != null) {
      for (final item in data['stock_history']) {
        await _db.insert(AppConstants.stockHistoryTable, Map<String, dynamic>.from(item));
      }
    }
  }

  // Helper to get or create Google Drive folder
  Future<String?> _getOrCreateFolder(drive.DriveApi driveApi, String folderName) async {
    // Search for existing folder
    final response = await driveApi.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      $fields: 'files(id, name)',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    }

    // Create new folder
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await driveApi.files.create(folder);
    return created.id;
  }
}

// Custom HTTP client for Google Auth
class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}

