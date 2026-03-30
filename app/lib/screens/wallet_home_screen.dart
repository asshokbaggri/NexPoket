import 'package:flutter/material.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔥 Balance Section
              const Text(
                "Total Balance",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 10),

              const Text(
                "\$12,450.00",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Actions
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
                          builder: (_) => const SendScreen(),
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
                          builder: (_) => const ReceiveScreen(),
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
                        const SnackBar(
                          content: Text("Buy feature coming soon"),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Your Assets",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              // 🔥 Token List
              Expanded(
                child: ListView(
                  children: const [

                    _TokenTile("Bitcoin", "BTC", "0.25", "\$7,500"),
                    _TokenTile("Ethereum", "ETH", "2.5", "\$4,200"),
                    _TokenTile("BNB", "BNB", "10", "\$750"),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Action Button (Clickable)
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
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.deepPurple,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

// 🔹 Token Tile
class _TokenTile extends StatelessWidget {
  final String name, symbol, amount, value;

  const _TokenTile(this.name, this.symbol, this.amount, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [

          const CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.currency_bitcoin, color: Colors.white),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white)),
              Text(symbol, style: const TextStyle(color: Colors.white70)),
            ],
          ),

          const Spacer(),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: Colors.white)),
              Text(value, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}