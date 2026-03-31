import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class WalletHomeScreen extends StatelessWidget {
  final String walletAddress;

  const WalletHomeScreen({super.key, required this.walletAddress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Wallet",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // 🔥 BALANCE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3375BB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Balance", style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text(
                      "0.00 ETH",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 ADDRESS
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        walletAddress,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: walletAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Address copied")),
                        );
                      },
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  _actionButton(
                    context,
                    Icons.send,
                    "Send",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendScreen(
                            walletAddress: walletAddress, // ✅ FIX
                          ),
                        ),
                      );
                    },
                  ),

                  _actionButton(
                    context,
                    Icons.download,
                    "Receive",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiveScreen(
                            walletAddress: walletAddress, // ✅ FIX
                          ),
                        ),
                      );
                    },
                  ),

                  _actionButton(
                    context,
                    Icons.add,
                    "Buy",
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming soon")),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Your Assets",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: Center(
                  child: Text(
                    "No assets yet",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 ACTION BUTTON
Widget _actionButton(
  BuildContext context,
  IconData icon,
  String label,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF3375BB).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF3375BB)),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    ),
  );
}