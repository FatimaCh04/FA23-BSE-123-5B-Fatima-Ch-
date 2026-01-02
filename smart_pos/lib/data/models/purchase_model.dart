class PurchaseModel {
  final String id;
  final String vendorId;
  final String? vendorName;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus; // paid, partial, unpaid
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? syncStatus;
  final String? userId;
  final List<PurchaseItemModel>? items;

  PurchaseModel({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.invoiceNumber,
    required this.purchaseDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.paymentStatus = 'unpaid',
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus,
    this.userId,
    this.items,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isPartial => paymentStatus == 'partial';
  bool get isUnpaid => paymentStatus == 'unpaid';

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'],
      invoiceNumber: json['invoice_number'] ?? '',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : DateTime.now(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      dueAmount: (json['due_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'unpaid',
      notes: json['notes'],
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
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate.toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_status': paymentStatus,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? invoiceNumber,
    DateTime? purchaseDate,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    String? paymentStatus,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? userId,
    List<PurchaseItemModel>? items,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
      items: items ?? this.items,
    );
  }
}

class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String? productName;
  final String? productSku;
  final int quantity;
  final double costPrice;
  final double totalPrice;
  final DateTime createdAt;
  final String? syncStatus;

  PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    this.productName,
    this.productSku,
    required this.quantity,
    required this.costPrice,
    required this.totalPrice,
    required this.createdAt,
    this.syncStatus,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] ?? '',
      purchaseId: json['purchase_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'],
      productSku: json['product_sku'],
      quantity: json['quantity'] ?? 0,
      costPrice: (json['cost_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      syncStatus: json['sync_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'cost_price': costPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  PurchaseItemModel copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    String? productSku,
    int? quantity,
    double? costPrice,
    double? totalPrice,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

