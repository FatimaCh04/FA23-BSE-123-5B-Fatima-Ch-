import '../../core/constants/app_constants.dart';

class StockHistoryModel {
  final String id;
  final String productId;
  final String? productName;
  final String operationType; // stock_in, stock_out, adjustment, sale, return, purchase
  final int quantityBefore;
  final int quantityChange;
  final int quantityAfter;
  final String? referenceId;
  final String? referenceType;
  final String? vendorId;      // Vendor who supplied (for purchase)
  final String? vendorName;
  final String? purchaseId;    // Purchase order reference
  final String? notes;
  final DateTime operationDate;
  final DateTime createdAt;
  final String? syncStatus;
  final String? userId;

  StockHistoryModel({
    required this.id,
    required this.productId,
    this.productName,
    required this.operationType,
    required this.quantityBefore,
    required this.quantityChange,
    required this.quantityAfter,
    this.referenceId,
    this.referenceType,
    this.vendorId,
    this.vendorName,
    this.purchaseId,
    this.notes,
    required this.operationDate,
    required this.createdAt,
    this.syncStatus,
    this.userId,
  });

  bool get isStockIn => operationType == AppConstants.stockIn;
  bool get isStockOut => operationType == AppConstants.stockOut;
  bool get isAdjustment => operationType == AppConstants.stockAdjust;
  bool get isSale => operationType == AppConstants.stockSale;
  bool get isReturn => operationType == AppConstants.stockReturn;

  factory StockHistoryModel.fromJson(Map<String, dynamic> json) {
    return StockHistoryModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'],
      operationType: json['operation_type'] ?? AppConstants.stockIn,
      quantityBefore: json['quantity_before'] ?? 0,
      quantityChange: json['quantity_change'] ?? 0,
      quantityAfter: json['quantity_after'] ?? 0,
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      purchaseId: json['purchase_id'],
      notes: json['notes'],
      operationDate: json['operation_date'] != null 
          ? DateTime.parse(json['operation_date']) 
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
      'product_id': productId,
      'product_name': productName,
      'operation_type': operationType,
      'quantity_before': quantityBefore,
      'quantity_change': quantityChange,
      'quantity_after': quantityAfter,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'purchase_id': purchaseId,
      'notes': notes,
      'operation_date': operationDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  StockHistoryModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? operationType,
    int? quantityBefore,
    int? quantityChange,
    int? quantityAfter,
    String? referenceId,
    String? referenceType,
    String? vendorId,
    String? vendorName,
    String? purchaseId,
    String? notes,
    DateTime? operationDate,
    DateTime? createdAt,
    String? syncStatus,
    String? userId,
  }) {
    return StockHistoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      operationType: operationType ?? this.operationType,
      quantityBefore: quantityBefore ?? this.quantityBefore,
      quantityChange: quantityChange ?? this.quantityChange,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      purchaseId: purchaseId ?? this.purchaseId,
      notes: notes ?? this.notes,
      operationDate: operationDate ?? this.operationDate,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }
}

