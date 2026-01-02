class AppConstants {
  // App Info
  static const String appName = 'Mobile Shop POS';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Mobile & Electronics Shop - Point of Sale';
  static const String shopType = 'Mobile & Electronics';
  
  // Default Categories for Mobile Shop
  static const List<String> defaultCategories = [
    'Smartphones',
    'Tablets',
    'Laptops',
    'Accessories',
    'Chargers & Cables',
    'Cases & Covers',
    'Earphones & Headphones',
    'Power Banks',
    'Smart Watches',
    'Spare Parts',
  ];
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String salesCollection = 'sales';
  static const String customersCollection = 'customers';
  static const String ledgerCollection = 'ledger';
  static const String inventoryCollection = 'inventory';
  static const String stockHistoryCollection = 'stock_history';
  static const String backupsCollection = 'backups';
  
  // SQLite Tables
  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String salesTable = 'sales';
  static const String saleItemsTable = 'sale_items';
  static const String customersTable = 'customers';
  static const String vendorsTable = 'vendors';
  static const String purchasesTable = 'purchases';
  static const String purchaseItemsTable = 'purchase_items';
  static const String ledgerTable = 'ledger';
  static const String inventoryTable = 'inventory';
  static const String stockHistoryTable = 'stock_history';
  static const String syncQueueTable = 'sync_queue';
  
  // Shared Preferences Keys
  static const String isLoggedInKey = 'is_logged_in';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String businessNameKey = 'business_name';
  static const String lastSyncKey = 'last_sync';
  static const String autoBackupKey = 'auto_backup';
  static const String backupIntervalKey = 'backup_interval';
  static const String lowStockThresholdKey = 'low_stock_threshold';
  static const String taxRateKey = 'tax_rate';
  static const String currencyKey = 'currency';
  
  // Default Values
  static const double defaultTaxRate = 0.0;
  static const int defaultLowStockThreshold = 10;
  static const String defaultCurrency = 'PKR';
  
  // Sync Status
  static const String syncPending = 'pending';
  static const String syncCompleted = 'completed';
  static const String syncFailed = 'failed';
  
  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentCredit = 'credit';
  static const String paymentBank = 'bank_transfer';
  
  // Customer Types
  static const String customerWalkIn = 'walk_in';
  static const String customerRegular = 'regular';
  
  // Transaction Types
  static const String transactionDebit = 'debit';
  static const String transactionCredit = 'credit';
  static const String transactionPayment = 'payment';
  
  // Stock Operations
  static const String stockIn = 'stock_in';
  static const String stockOut = 'stock_out';
  static const String stockAdjust = 'adjustment';
  static const String stockSale = 'sale';
  static const String stockReturn = 'return';
  
  // Backup Types
  static const String backupLocal = 'local';
  static const String backupGoogleDrive = 'google_drive';
  static const String backupAuto = 'auto';
  static const String backupManual = 'manual';
}

