import 'package:flutter/material.dart';
import 'seed_phrase_screen.dart'; // ✅ CONNECTED

class WalletSetupScreen extends StatelessWidget {
  const WalletSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const SizedBox(height: 40),

              // 🔐 Icon
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 30),

              const Text(
                "Welcome to NexPoket",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Create a new wallet or import an existing one.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),

              const Spacer(),

              // 🔥 Create Wallet Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SeedPhraseScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text("Create New Wallet"),
              ),

              const SizedBox(height: 15),

              // 🔥 Import Wallet Button
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Import wallet feature coming soon"),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text(
                  "I Already Have a Wallet",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}