class Patient {
  int id;
  String name;
  String dateOfBirth;
  String phoneNumber;
  String gender; // ✅ changed from email
  String address;
  String medicalHistory;
  String allergies;
  String? profileImagePath;
  DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.gender, // ✅
    required this.address,
    required this.medicalHistory,
    required this.allergies,
    this.profileImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'phoneNumber': phoneNumber,
      'gender': gender, // ✅
      'address': address,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      dateOfBirth: map['dateOfBirth'],
      phoneNumber: map['phoneNumber'],
      gender: map['gender'], // ✅
      address: map['address'],
      medicalHistory: map['medicalHistory'],
      allergies: map['allergies'],
      profileImagePath: map['profileImagePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
