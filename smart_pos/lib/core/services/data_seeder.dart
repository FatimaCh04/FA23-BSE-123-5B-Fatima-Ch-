import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../constants/app_constants.dart';

class DataSeeder {
  static final DataSeeder _instance = DataSeeder._internal();
  factory DataSeeder() => _instance;
  DataSeeder._internal();

  final _db = DatabaseHelper();
  final _uuid = const Uuid();

  // Mobile Shop Categories (5 main categories)
  final List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Smartphones',
      'description': 'Mobile phones and smartphones',
      'icon_name': 'phone_android',
      'image_url': null, // No network image - will use icon
      'color': '#0D4D47',
    },
    {
      'name': 'Accessories',
      'description': 'Mobile accessories - cases, covers, chargers',
      'icon_name': 'headphones',
      'image_url': null,
      'color': '#1A6B62',
    },
    {
      'name': 'Earphones',
      'description': 'Earphones, headphones and audio devices',
      'icon_name': 'headset',
      'image_url': null,
      'color': '#0A3D38',
    },
    {
      'name': 'Power Banks',
      'description': 'Portable chargers and power banks',
      'icon_name': 'battery_charging_full',
      'image_url': null,
      'color': '#0D4D47',
    },
    {
      'name': 'Smart Watches',
      'description': 'Smartwatches and fitness bands',
      'icon_name': 'watch',
      'image_url': null,
      'color': '#1A6B62',
    },
  ];

  // Sample Products for Mobile Shop (Offline - no network images)
  final List<Map<String, dynamic>> _sampleProducts = [
    // Smartphones
    {
      'name': 'iPhone 15 Pro Max',
      'description': 'Apple iPhone 15 Pro Max 256GB',
      'category': 'Smartphones',
      'cost_price': 380000,
      'sale_price': 420000,
      'quantity': 5,
      'image_url': null,
    },
    {
      'name': 'Samsung Galaxy S24 Ultra',
      'description': 'Samsung Galaxy S24 Ultra 256GB',
      'category': 'Smartphones',
      'cost_price': 320000,
      'sale_price': 360000,
      'quantity': 8,
      'image_url': null,
    },
    {
      'name': 'OnePlus 12',
      'description': 'OnePlus 12 5G 256GB',
      'category': 'Smartphones',
      'cost_price': 140000,
      'sale_price': 165000,
      'quantity': 12,
      'image_url': null,
    },
    
    // Accessories
    {
      'name': 'iPhone 15 Case',
      'description': 'Premium Silicon Case for iPhone 15',
      'category': 'Accessories',
      'cost_price': 500,
      'sale_price': 1000,
      'quantity': 50,
      'image_url': null,
    },
    {
      'name': 'USB-C Cable',
      'description': 'Fast Charging USB-C Cable 1m',
      'category': 'Accessories',
      'cost_price': 300,
      'sale_price': 600,
      'quantity': 100,
      'image_url': null,
    },
    {
      'name': 'Tempered Glass',
      'description': 'Screen Protector for All Phones',
      'category': 'Accessories',
      'cost_price': 150,
      'sale_price': 350,
      'quantity': 80,
      'image_url': null,
    },
    
    // Earphones
    {
      'name': 'AirPods Pro 2',
      'description': 'Apple AirPods Pro 2nd Gen',
      'category': 'Earphones',
      'cost_price': 45000,
      'sale_price': 55000,
      'quantity': 10,
      'image_url': null,
    },
    {
      'name': 'Samsung Buds2 Pro',
      'description': 'Samsung Galaxy Buds2 Pro',
      'category': 'Earphones',
      'cost_price': 28000,
      'sale_price': 35000,
      'quantity': 15,
      'image_url': null,
    },
    
    // Power Banks
    {
      'name': 'Anker 20000mAh',
      'description': 'Anker PowerCore 20000mAh',
      'category': 'Power Banks',
      'cost_price': 4500,
      'sale_price': 6500,
      'quantity': 25,
      'image_url': null,
    },
    {
      'name': 'Mi Power Bank 10000',
      'description': 'Xiaomi Mi Power Bank 10000mAh',
      'category': 'Power Banks',
      'cost_price': 2500,
      'sale_price': 3500,
      'quantity': 35,
      'image_url': null,
    },
    
    // Smart Watches
    {
      'name': 'Apple Watch Series 9',
      'description': 'Apple Watch Series 9 45mm',
      'category': 'Smart Watches',
      'cost_price': 85000,
      'sale_price': 99000,
      'quantity': 8,
      'image_url': null,
    },
    {
      'name': 'Samsung Galaxy Watch 6',
      'description': 'Samsung Galaxy Watch 6 Classic',
      'category': 'Smart Watches',
      'cost_price': 55000,
      'sale_price': 65000,
      'quantity': 10,
      'image_url': null,
    },
  ];

  // OLD PRODUCTS REMOVED - keeping only essential ones above
  final List<Map<String, dynamic>> _oldProducts = [
    // This list is kept for reference but not used
    {
      'name': 'MacBook Pro 14"',
      'description': 'Apple MacBook Pro 14 inch M3 Pro',
      'category': 'Laptops',
      'cost_price': 480000,
      'sale_price': 550000,
      'quantity': 3,
      'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400',
    },
    {
      'name': 'Dell XPS 15',
      'description': 'Dell XPS 15 Core i7 16GB RAM',
      'category': 'Laptops',
      'cost_price': 280000,
      'sale_price': 320000,
      'quantity': 5,
      'image_url': 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=400',
    },
    {
      'name': 'HP Pavilion 15',
      'description': 'HP Pavilion 15 Core i5 8GB RAM',
      'category': 'Laptops',
      'cost_price': 95000,
      'sale_price': 115000,
      'quantity': 8,
      'image_url': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=400',
    },
    
    // Accessories
    {
      'name': 'AirPods Pro 2',
      'description': 'Apple AirPods Pro 2nd Generation',
      'category': 'Earphones & Headphones',
      'cost_price': 45000,
      'sale_price': 55000,
      'quantity': 20,
      'image_url': 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=400',
    },
    {
      'name': 'Samsung Galaxy Buds Pro',
      'description': 'Samsung Galaxy Buds 2 Pro',
      'category': 'Earphones & Headphones',
      'cost_price': 28000,
      'sale_price': 35000,
      'quantity': 15,
      'image_url': 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=400',
    },
    {
      'name': 'Sony WH-1000XM5',
      'description': 'Sony WH-1000XM5 Wireless Headphones',
      'category': 'Earphones & Headphones',
      'cost_price': 65000,
      'sale_price': 78000,
      'quantity': 8,
      'image_url': 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=400',
    },
    
    // Chargers & Cables
    {
      'name': 'iPhone 20W Charger',
      'description': 'Apple 20W USB-C Power Adapter',
      'category': 'Chargers & Cables',
      'cost_price': 3500,
      'sale_price': 5000,
      'quantity': 50,
      'image_url': 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=400',
    },
    {
      'name': 'Samsung 45W Charger',
      'description': 'Samsung 45W Super Fast Charger',
      'category': 'Chargers & Cables',
      'cost_price': 4000,
      'sale_price': 5500,
      'quantity': 40,
      'image_url': 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400',
    },
    {
      'name': 'USB-C Cable 1m',
      'description': 'USB-C to USB-C Fast Charging Cable',
      'category': 'Chargers & Cables',
      'cost_price': 500,
      'sale_price': 800,
      'quantity': 100,
      'image_url': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
    },
    {
      'name': 'Lightning Cable',
      'description': 'Apple Lightning to USB-C Cable 1m',
      'category': 'Chargers & Cables',
      'cost_price': 1500,
      'sale_price': 2500,
      'quantity': 80,
      'image_url': 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=400',
    },
    
    // Cases & Covers
    {
      'name': 'iPhone 15 Clear Case',
      'description': 'Clear Protective Case for iPhone 15',
      'category': 'Cases & Covers',
      'cost_price': 300,
      'sale_price': 600,
      'quantity': 60,
      'image_url': 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=400',
    },
    {
      'name': 'Samsung S24 Back Cover',
      'description': 'Premium Silicon Case for Samsung S24',
      'category': 'Cases & Covers',
      'cost_price': 250,
      'sale_price': 500,
      'quantity': 70,
      'image_url': 'https://images.unsplash.com/photo-1603313011101-320f26dfe6ae?w=400',
    },
    {
      'name': 'Tempered Glass iPhone',
      'description': 'Screen Protector for iPhone 15 Series',
      'category': 'Cases & Covers',
      'cost_price': 150,
      'sale_price': 350,
      'quantity': 100,
      'image_url': 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
    },
    
    // Power Banks
    {
      'name': 'Anker 20000mAh',
      'description': 'Anker PowerCore 20000mAh Power Bank',
      'category': 'Power Banks',
      'cost_price': 4500,
      'sale_price': 6500,
      'quantity': 25,
      'image_url': 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400',
    },
    {
      'name': 'Mi Power Bank 10000',
      'description': 'Xiaomi Mi Power Bank 10000mAh',
      'category': 'Power Banks',
      'cost_price': 2500,
      'sale_price': 3500,
      'quantity': 35,
      'image_url': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=400',
    },
    
    // Smart Watches
    {
      'name': 'Apple Watch Ultra 2',
      'description': 'Apple Watch Ultra 2 GPS + Cellular',
      'category': 'Smart Watches',
      'cost_price': 150000,
      'sale_price': 180000,
      'quantity': 5,
      'image_url': 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=400',
    },
    {
      'name': 'Samsung Galaxy Watch 6',
      'description': 'Samsung Galaxy Watch 6 Classic',
      'category': 'Smart Watches',
      'cost_price': 55000,
      'sale_price': 68000,
      'quantity': 10,
      'image_url': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
    },
    {
      'name': 'Amazfit GTR 4',
      'description': 'Amazfit GTR 4 Smartwatch',
      'category': 'Smart Watches',
      'cost_price': 28000,
      'sale_price': 35000,
      'quantity': 15,
      'image_url': 'https://images.unsplash.com/photo-1617043786394-f977fa12eddf?w=400',
    },
    
    // Spare Parts
    {
      'name': 'iPhone Battery',
      'description': 'Replacement Battery for iPhone 12/13',
      'category': 'Spare Parts',
      'cost_price': 2500,
      'sale_price': 4500,
      'quantity': 30,
      'image_url': 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=400',
    },
    {
      'name': 'iPhone Screen LCD',
      'description': 'iPhone 13 Display Assembly',
      'category': 'Spare Parts',
      'cost_price': 8000,
      'sale_price': 15000,
      'quantity': 20,
      'image_url': 'https://images.unsplash.com/photo-1580910051074-3eb694886f8b?w=400',
    },
    {
      'name': 'Samsung Screen AMOLED',
      'description': 'Samsung Galaxy S23 AMOLED Screen',
      'category': 'Spare Parts',
      'cost_price': 12000,
      'sale_price': 22000,
      'quantity': 15,
      'image_url': 'https://images.unsplash.com/photo-1601972599748-19fe5dc007eb?w=400',
    },
  ];

  Future<void> seedDefaultData({String? userId}) async {
    await seedCategories(userId: userId);
    await seedProducts(userId: userId);
  }

  Future<void> seedCategories({String? userId}) async {
    try {
      // Check if categories already exist
      final existing = await _db.query(AppConstants.categoriesTable);
      if (existing.isNotEmpty) {
        return; // Don't seed if data exists
      }

      for (var categoryData in _defaultCategories) {
        final category = CategoryModel(
          id: _uuid.v4(),
          name: categoryData['name'],
          description: categoryData['description'],
          iconName: categoryData['icon_name'],
          imageUrl: categoryData['image_url'],
          color: categoryData['color'],
          isActive: true,
          createdAt: DateTime.now(),
          syncStatus: AppConstants.syncPending,
          userId: userId,
        );

        await _db.insert(AppConstants.categoriesTable, category.toJson());
      }
    } catch (e) {
      // Silently fail - categories might already exist
    }
  }

  Future<void> seedProducts({String? userId}) async {
    try {
      // Check if products already exist
      final existing = await _db.query(AppConstants.productsTable);
      if (existing.isNotEmpty) {
        return; // Don't seed if data exists
      }

      // Get categories to map names to IDs
      final categories = await _db.query(AppConstants.categoriesTable);
      final categoryMap = <String, String>{};
      for (var cat in categories) {
        categoryMap[cat['name'] as String] = cat['id'] as String;
      }

      int skuCounter = 1001;
      for (var productData in _sampleProducts) {
        final categoryId = categoryMap[productData['category']] ?? '';
        if (categoryId.isEmpty) continue;

        final product = ProductModel(
          id: _uuid.v4(),
          sku: 'SKU-${skuCounter++}',
          name: productData['name'],
          description: productData['description'],
          categoryId: categoryId,
          categoryName: productData['category'],
          costPrice: (productData['cost_price'] as num).toDouble(),
          salePrice: (productData['sale_price'] as num).toDouble(),
          quantity: productData['quantity'] as int,
          lowStockThreshold: 5,
          imageUrl: productData['image_url'],
          isActive: true,
          createdAt: DateTime.now(),
          syncStatus: AppConstants.syncPending,
          userId: userId,
        );

        await _db.insert(AppConstants.productsTable, product.toJson());
      }
    } catch (e) {
      // Silently fail - products might already exist
    }
  }

  // Force reseed (clears existing and adds new)
  Future<void> forceReseed({String? userId}) async {
    await _db.delete(AppConstants.productsTable);
    await _db.delete(AppConstants.categoriesTable);
    await seedDefaultData(userId: userId);
  }

  // Ensure 5 main categories always exist (won't delete existing data)
  Future<void> ensureCategories({String? userId}) async {
    try {
      // Get userId from SharedPreferences if not provided
      String? actualUserId = userId;
      if (actualUserId == null) {
        final prefs = await SharedPreferences.getInstance();
        actualUserId = prefs.getString(AppConstants.userIdKey);
      }
      
      // Get existing category names for this user
      final existingCategories = await _db.query(
        AppConstants.categoriesTable,
        where: actualUserId != null ? 'user_id = ?' : null,
        whereArgs: actualUserId != null ? [actualUserId] : null,
      );
      final existingNames = existingCategories.map((c) => c['name'] as String).toSet();

      // Add only missing categories from our 5 main categories
      for (var categoryData in _defaultCategories) {
        final name = categoryData['name'] as String;
        if (!existingNames.contains(name)) {
          final category = CategoryModel(
            id: _uuid.v4(),
            name: name,
            description: categoryData['description'],
            iconName: categoryData['icon_name'],
            imageUrl: categoryData['image_url'],
            color: categoryData['color'],
            isActive: true,
            createdAt: DateTime.now(),
            syncStatus: AppConstants.syncPending,
            userId: actualUserId,
          );
          await _db.insert(AppConstants.categoriesTable, category.toJson());
        }
      }
    } catch (e) {
      // Silently fail
      debugPrint('ensureCategories error: $e');
    }
  }

  // Add mobile shop data (adds to existing data, skips duplicates)
  Future<void> addMobileShopData({String? userId}) async {
    try {
      // Get existing category names to avoid duplicates
      final existingCategories = await _db.query(AppConstants.categoriesTable);
      final existingCategoryNames = existingCategories.map((c) => c['name'] as String).toSet();

      // Add categories that don't exist
      final addedCategoryMap = <String, String>{};
      
      // First, map existing categories
      for (var cat in existingCategories) {
        addedCategoryMap[cat['name'] as String] = cat['id'] as String;
      }

      // Add new categories
      for (var categoryData in _defaultCategories) {
        final name = categoryData['name'] as String;
        if (!existingCategoryNames.contains(name)) {
          final id = _uuid.v4();
          final category = CategoryModel(
            id: id,
            name: name,
            description: categoryData['description'],
            iconName: categoryData['icon_name'],
            imageUrl: categoryData['image_url'],
            color: categoryData['color'],
            isActive: true,
            createdAt: DateTime.now(),
            syncStatus: AppConstants.syncPending,
            userId: userId,
          );
          await _db.insert(AppConstants.categoriesTable, category.toJson());
          addedCategoryMap[name] = id;
        }
      }

      // Get existing product names to avoid duplicates
      final existingProducts = await _db.query(AppConstants.productsTable);
      final existingProductNames = existingProducts.map((p) => p['name'] as String).toSet();

      // Add products that don't exist
      int skuCounter = 2001;
      for (var productData in _sampleProducts) {
        final name = productData['name'] as String;
        final categoryName = productData['category'] as String;
        final categoryId = addedCategoryMap[categoryName];
        
        if (!existingProductNames.contains(name) && categoryId != null) {
          final product = ProductModel(
            id: _uuid.v4(),
            sku: 'MOB-${skuCounter++}',
            name: name,
            description: productData['description'],
            categoryId: categoryId,
            categoryName: categoryName,
            costPrice: (productData['cost_price'] as num).toDouble(),
            salePrice: (productData['sale_price'] as num).toDouble(),
            quantity: productData['quantity'] as int,
            lowStockThreshold: 5,
            imageUrl: productData['image_url'],
            isActive: true,
            createdAt: DateTime.now(),
            syncStatus: AppConstants.syncPending,
            userId: userId,
          );
          await _db.insert(AppConstants.productsTable, product.toJson());
        }
      }
    } catch (e) {
      // Log error
      print('Error adding mobile shop data: $e');
    }
  }
}

