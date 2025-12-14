import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';

// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: const TaskManagerApp(),
    ),
  );
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey, // ✅ attach navigator key
          debugShowCheckedModeBanner: false,
          title: 'Task Manager',
          themeMode: provider.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF8E24AA),
              secondary: const Color(0xFFF06292),
              background: const Color(0xFFF8EAF6),
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onBackground: Colors.black,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF8E24AA),
              foregroundColor: Colors.white,
              elevation: 6,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFAB47BC),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFBA68C8),
              secondary: Color(0xFFF48FB1),
              background: Color(0xFF1E1E2C),
              surface: Color(0xFF2C2C3E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFBA68C8),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
