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

            // 🔥 QR CARD (FIXED CONTRAST)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // हमेशा white (QR readable रहे)
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: QrImageView(
                data: walletAddress,
                version: QrVersions.auto,
                size: 200,
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 ADDRESS BOX (FIXED)
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
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black, // ✅ FIX
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 ACTION BUTTONS (FIXED)
            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => copyAddress(context),
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text(
                      "Copy",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3375BB),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: shareAddress,
                    icon: const Icon(Icons.share, color: Color(0xFF3375BB)),
                    label: const Text(
                      "Share",
                      style: TextStyle(color: Color(0xFF3375BB)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3375BB)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Only send supported assets to this address.",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}