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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Receive"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            // 🔳 QR Card
            Container(
              height: 200,
              width: 200,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),

              alignment: Alignment.center,
              child: const Text("QR"),
            ),

            const SizedBox(height: 20),

            // 🔹 Address
            Text(
              walletAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 🔥 Copy Button
            ElevatedButton(
              onPressed: () => copyAddress(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
              ),
              child: const Text("Copy Address"),
            ),
          ],
        ),
      ),
    );
  }
}