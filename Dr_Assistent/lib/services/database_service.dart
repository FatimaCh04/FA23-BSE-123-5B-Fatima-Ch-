import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import 'db_helper.dart';

class DatabaseService extends ChangeNotifier {
  // ✅ Use the singleton DBHelper instance
  final DBHelper _dbHelper = DBHelper.instance;

  List<Patient> _patients = [];
  List<Map<String, dynamic>> _appointments = [];
  final Map<int, List<Map<String, dynamic>>> _visits = {};
  bool _isLoading = false;

  // ------------------- GETTERS -------------------
  List<Patient> get patients => _patients;
  List<Map<String, dynamic>> get appointments => _appointments;
  bool get isLoading => _isLoading;

  // =====================================================
  //                  PATIENTS
  // =====================================================
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    final rows = await _dbHelper.getPatientsMap();
    _patients = rows.map((r) => _mapToPatient(r)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPatient(Patient p) async {
    await _dbHelper.insertPatientMap(_patientToMap(p));

    // ✅ Instead of reloading entire list, just add locally (faster)
    _patients.insert(0, p);
    notifyListeners();
  }

  Future<bool> updatePatient(Patient p) async {
    final rows = await _dbHelper.updatePatientMap(p.id, _patientToMap(p));

    if (rows > 0) {
      final index = _patients.indexWhere((pat) => pat.id == p.id);
      if (index != -1) _patients[index] = p;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deletePatientById(int id) async {
    final rows = await _dbHelper.deletePatient(id);
    await _dbHelper.deleteVisitsByPatientId(id);

    _patients.removeWhere((p) => p.id == id);
    _visits.remove(id);

    notifyListeners();
    return rows > 0;
  }

  // =====================================================
  //                  APPOINTMENTS
  // =====================================================
  Future<void> loadAppointments() async {
    final rows = await _dbHelper.getAppointments();
    _appointments = rows;
    notifyListeners();
  }

  Future<int> addAppointment({
    required int patientId,
    required String patientName,
    required DateTime date,
    String? reason,
  }) async {
    final map = {
      'patientId': patientId,
      'patientName': patientName,
      'date': date.toIso8601String(),
      'reason': reason ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    final id = await _dbHelper.insertAppointment(map);

    // ✅ Just add in memory (avoid reload)
    _appointments.insert(0, {...map, 'id': id});
    notifyListeners();
    return id;
  }

  Future<int> updateAppointment(int id, Map<String, dynamic> data) async {
    final normalized = Map<String, dynamic>.from(data);
    if (normalized['date'] is DateTime) {
      normalized['date'] = (normalized['date'] as DateTime).toIso8601String();
    }

    final rows = await _dbHelper.updateAppointment(id, normalized);
    if (rows > 0) await loadAppointments();
    return rows;
  }

  Future<int> deleteAppointmentById(int id) async {
    final rows = await _dbHelper.deleteAppointment(id);
    _appointments.removeWhere((a) => a['id'] == id);
    notifyListeners();
    return rows;
  }

  // Clear all patients and appointments
  Future<void> clearAllData() async {
    patients.clear();
    appointments.clear();

    // If using local database, also delete from DB tables:
    // await db.delete('patients');
    // await db.delete('appointments');

    notifyListeners(); // Update UI immediately
  }

  // =====================================================
  //                  VISITS
  // =====================================================
  Future<void> addVisit(Map<String, dynamic> visitData) async {
    final patientId = visitData['patientId'] as int;

    final visit = {
      'patientId': patientId,
      'visitDate': visitData['visitDate'] ?? DateTime.now().toIso8601String(),
      'diagnosis': visitData['diagnosis'] ?? '',
      'treatment': visitData['treatment'] ?? '',
      'notes': visitData['notes'] ?? '',
      'prescription': visitData['prescription'] ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // ✅ Insert to database and memory
    await _dbHelper.insertVisit(visit);
    _visits.putIfAbsent(patientId, () => []);
    _visits[patientId]!.insert(0, visit);

    notifyListeners();
  }

  Future<void> loadVisitsByPatient(int patientId) async {
    final rows = await _dbHelper.getVisitsByPatientId(patientId);
    _visits[patientId] = rows;
    notifyListeners();
  }

  List<Map<String, dynamic>> getVisitsByPatientId(int patientId) {
    return _visits[patientId] ?? [];
  }

  Future<void> clearVisits(int patientId) async {
    await _dbHelper.deleteVisitsByPatientId(patientId);
    _visits.remove(patientId);
    notifyListeners();
  }

  // =====================================================
  //                  HELPERS
  // =====================================================
  Patient _mapToPatient(Map<String, dynamic> m) {
    return Patient(
      id: m['id'] is int
          ? m['id'] as int
          : int.tryParse(m['id']?.toString() ?? '') ?? 0,
      name: m['name']?.toString() ?? '',
      dateOfBirth: m['dateOfBirth']?.toString() ?? '',
      phoneNumber: m['phoneNumber']?.toString() ?? '',
      gender: m['gender']?.toString() ?? '',
      address: m['address']?.toString() ?? '',
      medicalHistory: m['medicalHistory']?.toString() ?? '',
      allergies: m['allergies']?.toString() ?? '',
      profileImagePath: m['profileImagePath']?.toString(),
      createdAt:
      DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _patientToMap(Patient p) {
    return {
      'id': p.id,
      'name': p.name,
      'dateOfBirth': p.dateOfBirth,
      'phoneNumber': p.phoneNumber,
      'gender': p.gender,
      'address': p.address,
      'medicalHistory': p.medicalHistory,
      'allergies': p.allergies,
      'profileImagePath': p.profileImagePath,
      'createdAt': p.createdAt.toIso8601String(),
    };
  }
}
