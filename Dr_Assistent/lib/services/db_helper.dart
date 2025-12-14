// db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static const _dbName = 'dr_assistant.db';
  static const _dbVersion = 1;

  // ✅ Use a single shared instance (Singleton pattern)
  static Database? _database;
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  // ✅ Lazy-load the database only once
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ✅ Initialize database once and reuse it
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // ✅ Create tables (AUTOINCREMENT + optimized schema)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dateOfBirth TEXT,
        phoneNumber TEXT,
        gender TEXT,
        address TEXT,
        medicalHistory TEXT,
        allergies TEXT,
        profileImagePath TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        patientName TEXT,
        date TEXT,
        reason TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        visitDate TEXT,
        diagnosis TEXT,
        treatment TEXT,
        notes TEXT,
        prescription TEXT,
        createdAt TEXT
      )
    ''');
  }

  // ==================== PATIENTS ====================

  Future<int> insertPatientMap(Map<String, dynamic> map) async {
    final db = await database;
    return await db.insert(
      'patients',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPatientsMap() async {
    final db = await database;
    return await db.query(
      'patients',
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updatePatientMap(int id, Map<String, dynamic> map) async {
    final db = await database;
    return await db.update(
      'patients',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== APPOINTMENTS ====================

  Future<int> insertAppointment(Map<String, dynamic> map) async {
    final db = await database;
    return await db.insert(
      'appointments',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    return await db.query('appointments', orderBy: 'date DESC');
  }

  Future<int> updateAppointment(int id, Map<String, dynamic> map) async {
    final db = await database;
    return await db.update('appointments', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== VISITS ====================

  Future<int> insertVisit(Map<String, dynamic> visit) async {
    final db = await database;
    return await db.insert('visits', visit);
  }

  Future<List<Map<String, dynamic>>> getVisitsByPatientId(int patientId) async {
    final db = await database;
    return await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<void> deleteVisitsByPatientId(int patientId) async {
    final db = await database;
    await db.delete('visits', where: 'patientId = ?', whereArgs: [patientId]);
  }
}
