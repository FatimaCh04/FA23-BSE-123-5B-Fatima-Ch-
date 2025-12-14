import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/doctor_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => DatabaseService()..loadPatients()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const DrAssistantApp(),
    ),
  );
}

class DrAssistantApp extends StatelessWidget {
  const DrAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dr. Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.teal.shade50,
      ),
      home: const HomeScreen(),

      // 🔹 Add named routes here
      routes: {
        '/signup': (context) => const SignupScreen(),
        // '/dashboard': (context) => const DoctorDashboard(),
      },
    );
  }
}
