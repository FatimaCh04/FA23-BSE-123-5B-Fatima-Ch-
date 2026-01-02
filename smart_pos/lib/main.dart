import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/printer_service.dart';
import 'core/services/data_seeder.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/customer_provider.dart';
import 'presentation/providers/pos_provider.dart';
import 'presentation/providers/report_provider.dart';
import 'presentation/providers/vendor_provider.dart';
import 'presentation/providers/purchase_provider.dart';
import 'presentation/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (don't await - not critical)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize Firebase - must complete before services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize services - lightweight init only
  final connectivityService = ConnectivityService();
  final syncService = SyncService();
  final backupService = BackupService();
  final authService = AuthService();
  final printerService = PrinterService();

  // Initialize services in background after app starts
  Future.microtask(() async {
    await connectivityService.initialize();
    await authService.initialize();
    // These can run in parallel
    Future.wait([
      syncService.initialize(),
      backupService.initialize(),
      printerService.initialize(),
    ]);
    // Seed data - ensure 5 categories always exist
    DataSeeder().ensureCategories();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectivityService),
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProvider.value(value: backupService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: printerService),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => POSProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: const SmartPOSApp(),
    ),
  );
}

class SmartPOSApp extends StatelessWidget {
  const SmartPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
