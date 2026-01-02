import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_pos.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE ${AppConstants.usersTable} (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        business_name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        logo_url TEXT,
        role TEXT DEFAULT 'admin',
        parent_user_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE ${AppConstants.categoriesTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        image_url TEXT,
        color TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id TEXT PRIMARY KEY,
        sku TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category_id TEXT,
        category_name TEXT,
        cost_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        unit TEXT,
        vendor TEXT,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        has_discount INTEGER DEFAULT 0,
        has_tax INTEGER DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 10,
        barcode TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT,
        FOREIGN KEY (category_id) REFERENCES ${AppConstants.categoriesTable}(id)
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE ${AppConstants.customersTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        customer_type TEXT DEFAULT 'regular',
        total_purchases REAL DEFAULT 0,
        total_payments REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        last_purchase_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT
      )
    ''');

    // Vendors Table
    await db.execute('''
      CREATE TABLE ${AppConstants.vendorsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        company_name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        image_url TEXT,
        total_purchases REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT
      )
    ''');

    // Sales Table
    await db.execute('''
      CREATE TABLE ${AppConstants.salesTable} (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        discount_percent REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        tax_percent REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        due_amount REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        sale_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT,
        is_void INTEGER DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.customersTable}(id)
      )
    ''');

    // Sale Items Table
    await db.execute('''
      CREATE TABLE ${AppConstants.saleItemsTable} (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        sku TEXT,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        cost_price REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        total_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${AppConstants.salesTable}(id),
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productsTable}(id)
      )
    ''');

    // Ledger Table
    await db.execute('''
      CREATE TABLE ${AppConstants.ledgerTable} (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        customer_name TEXT,
        transaction_type TEXT NOT NULL,
        reference_id TEXT,
        reference_type TEXT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        balance_before REAL NOT NULL,
        balance_after REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.customersTable}(id)
      )
    ''');

    // Stock History Table
    await db.execute('''
      CREATE TABLE ${AppConstants.stockHistoryTable} (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT,
        operation_type TEXT NOT NULL,
        quantity_before INTEGER NOT NULL,
        quantity_change INTEGER NOT NULL,
        quantity_after INTEGER NOT NULL,
        reference_id TEXT,
        reference_type TEXT,
        vendor_id TEXT,
        vendor_name TEXT,
        purchase_id TEXT,
        notes TEXT,
        operation_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productsTable}(id)
      )
    ''');

    // Purchases Table
    await db.execute('''
      CREATE TABLE ${AppConstants.purchasesTable} (
        id TEXT PRIMARY KEY,
        vendor_id TEXT NOT NULL,
        vendor_name TEXT,
        invoice_number TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        subtotal REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        due_amount REAL DEFAULT 0,
        payment_status TEXT DEFAULT 'unpaid',
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        user_id TEXT,
        FOREIGN KEY (vendor_id) REFERENCES ${AppConstants.vendorsTable}(id)
      )
    ''');

    // Purchase Items Table
    await db.execute('''
      CREATE TABLE ${AppConstants.purchaseItemsTable} (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT,
        product_sku TEXT,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        total_price REAL NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (purchase_id) REFERENCES ${AppConstants.purchasesTable}(id),
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productsTable}(id)
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE ${AppConstants.syncQueueTable} (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_category ON ${AppConstants.productsTable}(category_id)');
    await db.execute('CREATE INDEX idx_products_sku ON ${AppConstants.productsTable}(sku)');
    await db.execute('CREATE INDEX idx_products_barcode ON ${AppConstants.productsTable}(barcode)');
    await db.execute('CREATE INDEX idx_sales_customer ON ${AppConstants.salesTable}(customer_id)');
    await db.execute('CREATE INDEX idx_sales_date ON ${AppConstants.salesTable}(sale_date)');
    await db.execute('CREATE INDEX idx_sale_items_sale ON ${AppConstants.saleItemsTable}(sale_id)');
    await db.execute('CREATE INDEX idx_ledger_customer ON ${AppConstants.ledgerTable}(customer_id)');
    await db.execute('CREATE INDEX idx_stock_history_product ON ${AppConstants.stockHistoryTable}(product_id)');
    await db.execute('CREATE INDEX idx_sync_queue_table ON ${AppConstants.syncQueueTable}(table_name)');
    await db.execute('CREATE INDEX idx_purchases_vendor ON ${AppConstants.purchasesTable}(vendor_id)');
    await db.execute('CREATE INDEX idx_purchases_date ON ${AppConstants.purchasesTable}(purchase_date)');
    await db.execute('CREATE INDEX idx_purchase_items_purchase ON ${AppConstants.purchaseItemsTable}(purchase_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add missing columns to users table
      try {
        await db.execute('ALTER TABLE ${AppConstants.usersTable} ADD COLUMN role TEXT DEFAULT "admin"');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE ${AppConstants.usersTable} ADD COLUMN parent_user_id TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    
    if (oldVersion < 3) {
      // Add new product fields for unit, vendor, discount, and tax
      try {
        await db.execute('ALTER TABLE ${AppConstants.productsTable} ADD COLUMN unit TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE ${AppConstants.productsTable} ADD COLUMN vendor TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE ${AppConstants.productsTable} ADD COLUMN discount REAL DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE ${AppConstants.productsTable} ADD COLUMN tax REAL DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE ${AppConstants.productsTable} ADD COLUMN has_discount INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE ${AppConstants.productsTable} ADD COLUMN has_tax INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
    }
    
    if (oldVersion < 4) {
      // Add image_url column to categories table
      try {
        await db.execute('ALTER TABLE ${AppConstants.categoriesTable} ADD COLUMN image_url TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    
    if (oldVersion < 5) {
      // Create vendors table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppConstants.vendorsTable} (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            company_name TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            image_url TEXT,
            total_purchases REAL DEFAULT 0,
            outstanding_balance REAL DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            sync_status TEXT DEFAULT 'pending',
            user_id TEXT
          )
        ''');
      } catch (e) {
        // Table might already exist
      }
    }
    
    if (oldVersion < 6) {
      // Add vendor tracking columns to stock_history
      try {
        await db.execute('ALTER TABLE ${AppConstants.stockHistoryTable} ADD COLUMN vendor_id TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE ${AppConstants.stockHistoryTable} ADD COLUMN vendor_name TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE ${AppConstants.stockHistoryTable} ADD COLUMN purchase_id TEXT');
      } catch (e) {}
    }
    
    if (oldVersion < 7) {
      // Create purchases table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppConstants.purchasesTable} (
            id TEXT PRIMARY KEY,
            vendor_id TEXT NOT NULL,
            vendor_name TEXT,
            invoice_number TEXT NOT NULL,
            purchase_date TEXT NOT NULL,
            subtotal REAL DEFAULT 0,
            tax_amount REAL DEFAULT 0,
            discount_amount REAL DEFAULT 0,
            total_amount REAL NOT NULL,
            paid_amount REAL DEFAULT 0,
            due_amount REAL DEFAULT 0,
            payment_status TEXT DEFAULT 'unpaid',
            notes TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            sync_status TEXT DEFAULT 'pending',
            user_id TEXT
          )
        ''');
      } catch (e) {}
      
      // Create purchase_items table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppConstants.purchaseItemsTable} (
            id TEXT PRIMARY KEY,
            purchase_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            product_name TEXT,
            product_sku TEXT,
            quantity INTEGER NOT NULL,
            cost_price REAL NOT NULL,
            total_price REAL NOT NULL,
            created_at TEXT NOT NULL,
            sync_status TEXT DEFAULT 'pending'
          )
        ''');
      } catch (e) {}
      
      // Create indexes
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_purchases_vendor ON ${AppConstants.purchasesTable}(vendor_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_purchases_date ON ${AppConstants.purchasesTable}(purchase_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON ${AppConstants.purchaseItemsTable}(purchase_id)');
      } catch (e) {}
    }
  }

  // Generic CRUD Operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  // Get pending sync records
  Future<List<Map<String, dynamic>>> getPendingSyncRecords(String tableName) async {
    return await query(
      tableName,
      where: 'sync_status = ?',
      whereArgs: [AppConstants.syncPending],
    );
  }

  // Mark record as synced
  Future<void> markAsSynced(String table, String id) async {
    await update(
      table,
      {'sync_status': AppConstants.syncCompleted, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Add to sync queue
  Future<void> addToSyncQueue(String tableName, String recordId, String operation, String data) async {
    await insert(AppConstants.syncQueueTable, {
      'id': '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}',
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Clear sync queue
  Future<void> clearSyncQueue() async {
    await delete(AppConstants.syncQueueTable);
  }

  // Get database for backup
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'smart_pos.db');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.saleItemsTable);
    await db.delete(AppConstants.salesTable);
    await db.delete(AppConstants.ledgerTable);
    await db.delete(AppConstants.stockHistoryTable);
    await db.delete(AppConstants.productsTable);
    await db.delete(AppConstants.categoriesTable);
    await db.delete(AppConstants.customersTable);
    await db.delete(AppConstants.syncQueueTable);
  }
}

