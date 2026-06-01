import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ADTechApp());
}

class ADTechApp extends StatelessWidget {
  const ADTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
