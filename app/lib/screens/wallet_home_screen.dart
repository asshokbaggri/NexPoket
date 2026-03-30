import 'package:flutter/material.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Theme based background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔥 Balance Section
              const Text(
                "Total Balance",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 8),

              const Text(
                "\$12,450.00",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 25),

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
                  color: Colors.black,
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

// 🔹 Action Button (Modern Style)
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
        Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ],
    ),
  );
}

// 🔹 Token Tile (Card UI)
class _TokenTile extends StatelessWidget {
  final String name, symbol, amount, value;

  const _TokenTile(this.name, this.symbol, this.amount, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        // 🔥 Soft shadow (premium feel)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [

          const CircleAvatar(
            backgroundColor: Color(0xFF3375BB),
            child: Icon(Icons.currency_bitcoin, color: Colors.white),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.black),
              ),
              Text(
                symbol,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(color: Colors.black),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}