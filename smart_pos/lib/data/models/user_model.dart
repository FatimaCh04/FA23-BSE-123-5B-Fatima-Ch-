class UserModel {
  final String id;
  final String email;
  final String name;
  final String businessName;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final String role; // admin, manager, cashier
  final String? parentUserId; // For staff members, this is the admin's ID
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
    this.role = 'admin',
    this.parentUserId,
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
      role: json['role'] ?? 'admin',
      parentUserId: json['parent_user_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1,
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
      'role': role,
      'parent_user_id': parentUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';
  
  bool canManageUsers() => role == 'admin';
  bool canManageProducts() => role == 'admin' || role == 'manager';
  bool canViewReports() => role == 'admin' || role == 'manager';
  bool canMakeSales() => true; // All roles can make sales

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? businessName,
    String? phone,
    String? address,
    String? logoUrl,
    String? role,
    String? parentUserId,
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
      role: role ?? this.role,
      parentUserId: parentUserId ?? this.parentUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

