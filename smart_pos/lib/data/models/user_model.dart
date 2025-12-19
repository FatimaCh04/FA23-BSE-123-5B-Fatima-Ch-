class UserModel {
  final String id;
  final String email;
  final String name;
  final String businessName;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? syncStatus;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.businessName,
    this.phone,
    this.address,
    this.logoUrl,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.syncStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      businessName: json['business_name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      logoUrl: json['logo_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      isActive: json['is_active'] ?? true,
      syncStatus: json['sync_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'business_name': businessName,
      'phone': phone,
      'address': address,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'sync_status': syncStatus,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? businessName,
    String? phone,
    String? address,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? syncStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

