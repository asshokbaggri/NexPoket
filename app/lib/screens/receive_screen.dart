import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ReceiveScreen extends StatelessWidget {
  final String walletAddress;

  const ReceiveScreen({super.key, required this.walletAddress});

  void copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: walletAddress));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address copied")),
    );
  }

  void shareAddress() {
    Share.share(walletAddress);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Receive"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            // 🔥 REAL QR CODE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: walletAddress,
                version: QrVersions.auto,
                size: 200,
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 ADDRESS BOX
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                walletAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 ACTION BUTTONS
            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => copyAddress(context),
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3375BB),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: shareAddress,
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Only send supported assets to this address.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}