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

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
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