import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/local/database_helper.dart';
import '../../core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  final DatabaseHelper _db = DatabaseHelper();
  bool _firebaseInitialized = false;
  
  void _initFirebase() {
    if (_firebaseInitialized) return;
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _firebaseInitialized = true;
    } catch (e) {
      debugPrint('Firebase not available: $e');
    }
  }

  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
    _initFirebase();
    
    // Only subscribe to auth changes if Firebase is available
    if (_auth != null) {
      _auth!.authStateChanges().listen((user) async {
        _firebaseUser = user;
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          _currentUser = null;
          _isAuthenticated = false;
        }
        notifyListeners();
      });
    }

    // Check for existing session
    await _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;
    final userId = prefs.getString(AppConstants.userIdKey);

    if (isLoggedIn && userId != null) {
      // Try to load from local database first
      final localUsers = await _db.query(
        AppConstants.usersTable,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (localUsers.isNotEmpty) {
        _currentUser = UserModel.fromJson(localUsers.first);
        _isAuthenticated = true;
        notifyListeners();
      }
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      // Try to get from Firestore first (if available)
      if (_firestore != null) {
        final doc = await _firestore!.collection(AppConstants.usersCollection).doc(uid).get();
        
        if (doc.exists) {
          _currentUser = UserModel.fromJson({...doc.data()!, 'id': uid});
          
          // Save to local database
          await _db.insert(AppConstants.usersTable, _currentUser!.toJson());
          
          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.isLoggedInKey, true);
          await prefs.setString(AppConstants.userIdKey, uid);
          await prefs.setString(AppConstants.userEmailKey, _currentUser!.email);
          await prefs.setString(AppConstants.userNameKey, _currentUser!.name);
          await prefs.setString(AppConstants.businessNameKey, _currentUser!.businessName);
          
          _isAuthenticated = true;
          return;
        }
      }
      throw Exception('Load from local');
    } catch (e) {
      // If offline, try to load from local database
      final localUsers = await _db.query(
        AppConstants.usersTable,
        where: 'id = ?',
        whereArgs: [uid],
      );

      if (localUsers.isNotEmpty) {
        _currentUser = UserModel.fromJson(localUsers.first);
        _isAuthenticated = true;
      }
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String businessName,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create Firebase Auth user (if Firebase is available)
      UserCredential? credential;
      String oderId;
      
      if (_auth != null) {
        credential = await _auth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user == null) {
          throw Exception('Failed to create user');
        }
        oderId = credential.user!.uid;
      } else {
        // Offline mode - generate local ID
        oderId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Create user model
      final user = UserModel(
        id: oderId,
        email: email,
        name: name,
        businessName: businessName,
        phone: phone,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      // Save to local database FIRST (always works)
      await _db.insert(AppConstants.usersTable, user.toJson());

      // Try to save to Firestore (may fail if offline or rules not set)
      if (_firestore != null) {
        try {
          await _firestore!
              .collection(AppConstants.usersCollection)
              .doc(user.id)
              .set(user.toJson());
          
          // Mark as synced if successful
          await _db.markAsSynced(AppConstants.usersTable, user.id);
        } catch (firestoreError) {
          // Firestore failed - that's OK, data is saved locally
          // Will sync later when online
          debugPrint('Firestore save failed (will sync later): $firestoreError');
        }
      }

      // Update preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.userEmailKey, user.email);
      await prefs.setString(AppConstants.userNameKey, user.name);
      await prefs.setString(AppConstants.businessNameKey, user.businessName);

      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth == null) {
        throw Exception('Firebase is not available. Please check your internet connection.');
      }
      
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Try to load user data (handles both online and offline)
        await _loadUserData(credential.user!.uid);
        
        // If user data still null, create basic user from auth info
        if (_currentUser == null) {
          _currentUser = UserModel(
            id: credential.user!.uid,
            email: email,
            name: email.split('@').first,
            businessName: 'My Business',
            createdAt: DateTime.now(),
            syncStatus: AppConstants.syncPending,
          );
          
          // Save locally
          await _db.insert(AppConstants.usersTable, _currentUser!.toJson());
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.isLoggedInKey, true);
          await prefs.setString(AppConstants.userIdKey, _currentUser!.id);
          await prefs.setString(AppConstants.userEmailKey, _currentUser!.email);
        }
        
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw Exception('Sign in failed');
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInOffline({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check local database for user
      final localUsers = await _db.query(
        AppConstants.usersTable,
        where: 'email = ?',
        whereArgs: [email],
      );

      if (localUsers.isEmpty) {
        _errorMessage = 'No offline data found. Please connect to internet for first login.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // In offline mode, we trust the local data
      // In production, you'd want to hash and verify the password locally
      _currentUser = UserModel.fromJson(localUsers.first);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(AppConstants.userIdKey, _currentUser!.id);
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (_auth != null) {
      try {
        await _auth!.signOut();
      } catch (e) {
        debugPrint('Firebase sign out error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isLoggedInKey, false);
    await prefs.remove(AppConstants.userIdKey);

    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth == null) {
        throw Exception('Firebase is not available');
      }
      await _auth!.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? businessName,
    String? phone,
    String? address,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        businessName: businessName ?? _currentUser!.businessName,
        phone: phone ?? _currentUser!.phone,
        address: address ?? _currentUser!.address,
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      // Update local database
      await _db.update(
        AppConstants.usersTable,
        updatedUser.toJson(),
        where: 'id = ?',
        whereArgs: [updatedUser.id],
      );

      // Try to update Firestore
      if (_firestore != null) {
        try {
          await _firestore!
              .collection(AppConstants.usersCollection)
              .doc(updatedUser.id)
              .update(updatedUser.toJson());

          // Mark as synced
          await _db.markAsSynced(AppConstants.usersTable, updatedUser.id);
        } catch (e) {
          debugPrint('Firestore update failed (offline): $e');
        }
      }

      _currentUser = updatedUser;
      
      // Update preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userNameKey, updatedUser.name);
      await prefs.setString(AppConstants.businessNameKey, updatedUser.businessName);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: $code';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

