class VendorModel {
  final String id;
  final String name;
  final String? companyName;
  final String? phone;
  final String? email;
  final String? address;
  final String? imageUrl;
  final double totalPurchases;
  final double outstandingBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? syncStatus;
  final String? userId;

  VendorModel({
    required this.id,
    required this.name,
    this.companyName,
    this.phone,
    this.email,
    this.address,
    this.imageUrl,
    this.totalPurchases = 0,
    this.outstandingBalance = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus,
    this.userId,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      companyName: json['company_name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      imageUrl: json['image_url'],
      totalPurchases: (json['total_purchases'] ?? 0).toDouble(),
      outstandingBalance: (json['outstanding_balance'] ?? 0).toDouble(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      syncStatus: json['sync_status'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company_name': companyName,
      'phone': phone,
      'email': email,
      'address': address,
      'image_url': imageUrl,
      'total_purchases': totalPurchases,
      'outstanding_balance': outstandingBalance,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  VendorModel copyWith({
    String? id,
    String? name,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? imageUrl,
    double? totalPurchases,
    double? outstandingBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? userId,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }
}

