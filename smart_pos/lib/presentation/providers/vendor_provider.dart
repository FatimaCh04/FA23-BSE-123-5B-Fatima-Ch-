import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/vendor_model.dart';

class VendorProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<VendorModel> _vendors = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VendorModel> get vendors => _vendors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadVendors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final results = await _db.query(
        AppConstants.vendorsTable,
        orderBy: 'name ASC',
      );

      _vendors = results.map((json) => VendorModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load vendors: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVendor({
    required String name,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);

      final vendor = VendorModel(
        id: _uuid.v4(),
        name: name,
        companyName: companyName,
        phone: phone,
        email: email,
        address: address,
        imageUrl: imageUrl,
        isActive: true,
        createdAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
        userId: userId,
      );

      await _db.insert(AppConstants.vendorsTable, vendor.toJson());
      _vendors.insert(0, vendor);
      
      // Sort by name
      _vendors.sort((a, b) => a.name.compareTo(b.name));
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add vendor: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVendor({
    required String id,
    required String name,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? imageUrl,
    bool isActive = true,
  }) async {
    try {
      final index = _vendors.indexWhere((v) => v.id == id);
      if (index == -1) return false;

      final updatedVendor = _vendors[index].copyWith(
        name: name,
        companyName: companyName,
        phone: phone,
        email: email,
        address: address,
        imageUrl: imageUrl,
        isActive: isActive,
        updatedAt: DateTime.now(),
        syncStatus: AppConstants.syncPending,
      );

      await _db.update(
        AppConstants.vendorsTable,
        updatedVendor.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _vendors[index] = updatedVendor;
      
      // Sort by name
      _vendors.sort((a, b) => a.name.compareTo(b.name));
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update vendor: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVendor(String id) async {
    try {
      await _db.delete(
        AppConstants.vendorsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      _vendors.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete vendor: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  VendorModel? getVendorById(String id) {
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }
}

