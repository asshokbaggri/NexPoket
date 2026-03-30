import 'package:flutter/material.dart';
import 'core/app_shell.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const NexPoketApp());
}

class NexPoketApp extends StatelessWidget {
  const NexPoketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexPoket',
      debugShowCheckedModeBanner: false,

      // 🔥 LIGHT THEME (Trust Wallet Style)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF3375BB),

        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3375BB),
          brightness: Brightness.light,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF3375BB),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),

        useMaterial3: true,
      ),

      home: const SplashScreen(),

      routes: {
        '/home': (context) => const AppShell(),
      },
    );
  }
}