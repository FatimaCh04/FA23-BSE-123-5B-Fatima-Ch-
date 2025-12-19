import '../../core/constants/app_constants.dart';

class LedgerModel {
  final String id;
  final String customerId;
  final String? customerName;
  final String transactionType; // debit, credit, payment
  final String? referenceId; // sale_id or payment reference
  final String? referenceType; // sale, payment, adjustment
  final String description;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String? syncStatus;
  final String? userId;

  LedgerModel({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.transactionType,
    this.referenceId,
    this.referenceType,
    required this.description,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.transactionDate,
    required this.createdAt,
    this.syncStatus,
    this.userId,
  });

  bool get isDebit => transactionType == AppConstants.transactionDebit;
  bool get isCredit => transactionType == AppConstants.transactionCredit;
  bool get isPayment => transactionType == AppConstants.transactionPayment;

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'],
      transactionType: json['transaction_type'] ?? AppConstants.transactionDebit,
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      balanceBefore: (json['balance_before'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      transactionDate: json['transaction_date'] != null 
          ? DateTime.parse(json['transaction_date']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      syncStatus: json['sync_status'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'transaction_type': transactionType,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'description': description,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  LedgerModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? transactionType,
    String? referenceId,
    String? referenceType,
    String? description,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? syncStatus,
    String? userId,
  }) {
    return LedgerModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      transactionType: transactionType ?? this.transactionType,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }
}

