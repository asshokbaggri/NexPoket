// app/lib/screens/wallet_setup_screen.dart

import 'package:flutter/material.dart';
import 'seed_phrase_screen.dart';
import 'import_wallet_screen.dart';

class WalletSetupScreen extends StatelessWidget {
  const WalletSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              const SizedBox(height: 40),

              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Color(0xFF3375BB),
              ),

              const SizedBox(height: 30),

              const Text(
                "Welcome to NexPoket",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Create a new wallet or import an existing one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const Spacer(),

              // CREATE
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
                  backgroundColor: const Color(0xFF3375BB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text("Create New Wallet"),
              ),

              const SizedBox(height: 15),

              // IMPORT
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImportWalletScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text("I Already Have a Wallet"),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}