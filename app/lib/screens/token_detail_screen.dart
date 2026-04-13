// app/lib/screens/token_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/wallet_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class TokenDetailScreen extends StatelessWidget {
  final String symbol;
  final double balance;
  final double price;
  final double change;
  final String walletAddress;

  // 🔥 NEW (IMPORTANT FOR ICON FIX)
  final String network;
  final String contract;
  final bool isNative;

  const TokenDetailScreen({
    super.key,
    required this.symbol,
    required this.balance,
    required this.price,
    required this.change,
    required this.walletAddress,

    // 🔥 ADD THESE
    required this.network,
    required this.contract,
    required this.isNative,
  });

  @override
  Widget build(BuildContext context) {

    final usdValue = balance * price;

    // 🔥 ICON PATHS
    final iconPath = WalletService.resolveLocalIcon(symbol);

    final fallbackUrl = WalletService.resolveFallbackIcon(
      network: network,
      contract: contract,
      isNative: isNative,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // 🔥 FIXED ICON SYSTEM
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return Image.network(
                      fallbackUrl,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.currency_bitcoin, size: 20),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            Text(symbol),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 PRICE SECTION
            Center(
              child: Column(
                children: [
                  Text(
                    "\$${price.toStringAsFixed(4)}",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "${change >= 0 ? "+" : ""}${change.toStringAsFixed(2)}%",
                    style: TextStyle(
                      color: change >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 CHART PLACEHOLDER
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text("Chart Coming Soon 📊"),
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 HOLDINGS
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Holdings"),
                      Text(
                        balance.toStringAsFixed(6),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Value"),
                      Text(
                        "\$${usdValue.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                _btn(context, Icons.send, "Send", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendScreen(
                        walletAddress: walletAddress,
                      ),
                    ),
                  );
                }),

                _btn(context, Icons.download, "Receive", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiveScreen(
                        walletAddress: walletAddress,
                      ),
                    ),
                  );
                }),

                _btn(context, Icons.swap_horiz, "Swap", () {}),

                _btn(context, Icons.shopping_cart, "Buy", () {}),
              ],
            ),

            const SizedBox(height: 30),

            // 🔥 TRANSACTION HISTORY
            const Text(
              "Transaction History",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              height: 120,
              width: double.infinity,
              alignment: Alignment.center,
              child: const Text(
                "Coming Soon",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF3375BB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF3375BB)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}