import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider(),
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
          debugShowCheckedModeBanner: false,
          title: 'Task Manager',
          themeMode: provider.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8E24AA),
              secondary: Color(0xFFF06292),
              background: Color(0xFFF8EAF6),
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onBackground: Colors.black,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF8E24AA),
              foregroundColor: Colors.white,
              elevation: 6,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.1,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFAB47BC),
              foregroundColor: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
              bodyMedium: TextStyle(fontSize: 15),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFBA68C8),
              secondary: Color(0xFFF48FB1),
              background: Color(0xFF1E1E2C),
              surface: Color(0xFF2C2C3E),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFBA68C8),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
