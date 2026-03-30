import 'dart:async';
import 'package:flutter/material.dart';
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

    // ⏱ Safe navigation
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        // 🔥 Premium gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3375BB),
              Color(0xFF5FA8FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔹 Logo
            Image.asset(
              'assets/icon.png',
              width: 110,
            ),

            const SizedBox(height: 20),

            // 🔹 App Name
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

            // 🔹 Tagline
            const Text(
              "Smart Digital Wallet",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}