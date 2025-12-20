import '../../core/constants/app_constants.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String customerType; // walk_in or regular
  final double totalPurchases;
  final double totalPayments;
  final double outstandingBalance;
  final DateTime? lastPurchaseDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? syncStatus;
  final String? userId;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.customerType = AppConstants.customerRegular,
    this.totalPurchases = 0.0,
    this.totalPayments = 0.0,
    this.outstandingBalance = 0.0,
    this.lastPurchaseDate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus,
    this.userId,
  });

  bool get isWalkIn => customerType == AppConstants.customerWalkIn;
  bool get hasOutstanding => outstandingBalance > 0;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      customerType: json['customer_type'] ?? AppConstants.customerRegular,
      totalPurchases: (json['total_purchases'] ?? 0).toDouble(),
      totalPayments: (json['total_payments'] ?? 0).toDouble(),
      outstandingBalance: (json['outstanding_balance'] ?? 0).toDouble(),
      lastPurchaseDate: json['last_purchase_date'] != null 
          ? DateTime.parse(json['last_purchase_date']) 
          : null,
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
      'phone': phone,
      'email': email,
      'address': address,
      'customer_type': customerType,
      'total_purchases': totalPurchases,
      'total_payments': totalPayments,
      'outstanding_balance': outstandingBalance,
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? customerType,
    double? totalPurchases,
    double? totalPayments,
    double? outstandingBalance,
    DateTime? lastPurchaseDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? userId,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      customerType: customerType ?? this.customerType,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPayments: totalPayments ?? this.totalPayments,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }

  static CustomerModel walkInCustomer() {
    return CustomerModel(
      id: 'walk_in',
      name: 'Walk-in Customer',
      customerType: AppConstants.customerWalkIn,
      createdAt: DateTime.now(),
    );
  }
}

