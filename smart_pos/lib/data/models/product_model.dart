class ProductModel {
  final String id;
  final String sku;
  final String name;
  final String? description;
  final String categoryId;
  final String? categoryName;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final int lowStockThreshold;
  final String? barcode;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? syncStatus;
  final String? userId;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    required this.categoryId,
    this.categoryName,
    required this.costPrice,
    required this.salePrice,
    this.quantity = 0,
    this.lowStockThreshold = 10,
    this.barcode,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus,
    this.userId,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity <= 0;
  double get profit => salePrice - costPrice;
  double get profitMargin => costPrice > 0 ? ((salePrice - costPrice) / costPrice) * 100 : 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'],
      costPrice: (json['cost_price'] ?? 0).toDouble(),
      salePrice: (json['sale_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 10,
      barcode: json['barcode'],
      imageUrl: json['image_url'],
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
      'sku': sku,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'barcode': barcode,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? sku,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    double? costPrice,
    double? salePrice,
    int? quantity,
    int? lowStockThreshold,
    String? barcode,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? userId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      userId: userId ?? this.userId,
    );
  }
}

