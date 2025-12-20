import '../../core/constants/app_constants.dart';

class SaleModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String? customerName;
  final List<SaleItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double taxAmount;
  final double taxPercent;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentMethod;
  final String? notes;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? syncStatus;
  final String? userId;
  final bool isVoid;

  SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    this.taxAmount = 0.0,
    this.taxPercent = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    this.dueAmount = 0.0,
    this.paymentMethod = AppConstants.paymentCash,
    this.notes,
    required this.saleDate,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus,
    this.userId,
    this.isVoid = false,
  });

  bool get isPaid => dueAmount <= 0;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalProfit => items.fold(0.0, (sum, item) => sum + item.profit);

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'],
      items: json['items'] != null 
          ? (json['items'] as List).map((e) => SaleItemModel.fromJson(e)).toList()
          : [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      taxPercent: (json['tax_percent'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      dueAmount: (json['due_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? AppConstants.paymentCash,
      notes: json['notes'],
      saleDate: json['sale_date'] != null 
          ? DateTime.parse(json['sale_date']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      syncStatus: json['sync_status'],
      userId: json['user_id'],
      isVoid: json['is_void'] == true || json['is_void'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_percent': discountPercent,
      'tax_amount': taxAmount,
      'tax_percent': taxPercent,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'sale_date': saleDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
      'is_void': isVoid ? 1 : 0,
    };
  }

  SaleModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    List<SaleItemModel>? items,
    double? subtotal,
    double? discountAmount,
    double? discountPercent,
    double? taxAmount,
    double? taxPercent,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    String? paymentMethod,
    String? notes,
    DateTime? saleDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? userId,
    bool? isVoid,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
      isVoid: isVoid ?? this.isVoid,
    );
  }
}

class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double costPrice;
  final double discountAmount;
  final double totalPrice;

  SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    this.costPrice = 0.0,
    this.discountAmount = 0.0,
    required this.totalPrice,
  });

  double get profit => (unitPrice - costPrice - discountAmount) * quantity;

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] ?? '',
      saleId: json['sale_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      costPrice: (json['cost_price'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount_amount': discountAmount,
      'total_price': totalPrice,
    };
  }

  SaleItemModel copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    double? unitPrice,
    double? costPrice,
    double? discountAmount,
    double? totalPrice,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

