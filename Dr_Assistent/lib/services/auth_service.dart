import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _signedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isSignedIn => _signedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Simulate Google Sign-In
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      _signedIn = true;
    } catch (e) {
      _errorMessage = 'Sign-in failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign-Out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _signedIn = false;
    _isLoading = false;
    notifyListeners();
  }
}
