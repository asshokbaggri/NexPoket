import 'dart:async';
import 'package:flutter/material.dart';
import '../core/storage_service.dart';
import '../core/app_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final address = await StorageService.getAddress();

    if (address != null && address.isNotEmpty) {
      // ✅ AUTO LOGIN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppShell(walletAddress: address),
        ),
      );
    } else {
      // ❌ FIRST TIME USER
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3375BB),
              Color(0xFF4A90E2), // smoother gradient
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              'assets/icon.png',
              width: 110,
            ),

            const SizedBox(height: 20),

            const Text(
              "NexPoket",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Smart Digital Wallet",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 30),

            // 🔄 LOADING INDICATOR (premium feel)
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}