# Smart POS - Full Inventory Management App

A production-ready Point of Sale (POS) and Inventory Management application built with Flutter.

![Smart POS Banner](https://via.placeholder.com/800x400/1A535C/FFFFFF?text=Smart+POS+%26+Inventory+Management)

## 📱 Features

### ✅ Authentication
- Email/Password Authentication via Firebase
- Offline login support
- User profile management
- Business profile setup

### ✅ Product Management
- Add/Edit/Delete products
- SKU, barcode, and category management
- Cost price & sale price tracking
- Product images support
- Bulk product operations

### ✅ Inventory Control
- Real-time stock tracking
- Stock in/out operations
- Low stock alerts
- Stock adjustment with history
- Complete stock history log

### ✅ POS System (Billing)
- Intuitive cart management
- Quantity +/- controls
- Runtime price change
- Discount (% or fixed amount)
- Tax calculation
- Multiple payment methods (Cash, Card, Credit)
- Invoice generation
- Customer selection

### ✅ Customer Management
- Walk-in & regular customers
- Purchase history tracking
- Outstanding balance management
- Customer search & filter

### ✅ Ledger System
- Debit/Credit tracking
- Payment recording
- Outstanding balance overview
- Complete transaction history
- Customer-wise ledger

### ✅ Reports
- Daily sales report
- Monthly sales report
- Stock report
- Customer report
- Top selling products
- Profit analysis

### ✅ Offline Mode
- SQLite local database
- Offline sales processing
- Automatic data sync when online
- Conflict resolution

### ✅ Sync System
- Auto sync when internet restored
- Background sync
- Sync queue management
- Pending sync indicator

### ✅ Backup System
- Local backup to device storage
- Google Drive backup (compulsory)
- Auto backup scheduling
- One-click restore
- Backup management

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Local Database**: SQLite (sqflite)
- **State Management**: Provider
- **Cloud Backup**: Google Drive API

## 📋 Requirements

- Flutter SDK 3.5.0 or higher
- Dart SDK 3.5.0 or higher
- Android SDK 23+ (Android 6.0)
- iOS 12.0+
- Firebase project setup

## 🚀 Installation

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/smart_pos.git
cd smart_pos
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Email/Password Authentication
3. Create a Firestore database
4. Download `google-services.json` and place in `android/app/`
5. Download `GoogleService-Info.plist` and place in `ios/Runner/`

### 4. Google Sign-In Setup (for Google Drive backup)
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable Google Drive API
3. Configure OAuth consent screen
4. Add SHA-1 fingerprint to Firebase

### 5. Run the app
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── backup_service.dart
│   │   ├── connectivity_service.dart
│   │   └── sync_service.dart
│   └── utils/
├── data/
│   ├── local/
│   │   └── database_helper.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   ├── category_model.dart
│   │   ├── customer_model.dart
│   │   ├── sale_model.dart
│   │   ├── ledger_model.dart
│   │   └── stock_history_model.dart
│   └── repositories/
├── presentation/
│   ├── providers/
│   │   ├── product_provider.dart
│   │   ├── customer_provider.dart
│   │   ├── pos_provider.dart
│   │   └── report_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── products/
│   │   ├── inventory/
│   │   ├── pos/
│   │   ├── customers/
│   │   ├── ledger/
│   │   ├── reports/
│   │   ├── settings/
│   │   └── backup/
│   └── widgets/
└── main.dart
```

## 📸 Screenshots

| Dashboard | POS Screen | Products |
|-----------|------------|----------|
| ![Dashboard](screenshots/dashboard.png) | ![POS](screenshots/pos.png) | ![Products](screenshots/products.png) |

| Inventory | Customers | Reports |
|-----------|-----------|---------|
| ![Inventory](screenshots/inventory.png) | ![Customers](screenshots/customers.png) | ![Reports](screenshots/reports.png) |

| Backup | Settings | Ledger |
|--------|----------|--------|
| ![Backup](screenshots/backup.png) | ![Settings](screenshots/settings.png) | ![Ledger](screenshots/ledger.png) |

## 📦 APK Download

Download the latest APK: [Smart POS v1.0.0](releases/smart_pos_v1.0.0.apk)

## 🔒 Security Features

- Firebase Authentication
- Encrypted local storage
- Secure API communications
- User data isolation

## 🌐 Offline Capabilities

The app is designed with offline-first architecture:
- All data is stored locally in SQLite
- Sales can be processed without internet
- Automatic sync when connection is restored
- Conflict resolution for data consistency

## 📊 Data Backup

### Local Backup
- Stored in app documents directory
- JSON format for easy portability
- Manual and automatic backup options

### Google Drive Backup
- Requires Google Sign-In
- Stored in "Smart POS Backups" folder
- Easy restore from any device

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

## 🙏 Acknowledgments

- Flutter Team
- Firebase Team
- All contributors

---

Made with ❤️ using Flutter
