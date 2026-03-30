import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  final String walletAddress =
      "0xA1B2C3D4E5F678901234567890ABCDEF12345678";

  void copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: walletAddress));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address copied")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text("Receive"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            // 🔳 Fake QR (placeholder)
            Container(
              height: 200,
              width: 200,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Text("QR"),
            ),

            const SizedBox(height: 20),

            Text(
              walletAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => copyAddress(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Copy Address"),
            ),
          ],
        ),
      ),
    );
  }
}