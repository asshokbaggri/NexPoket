import 'package:flutter/material.dart';

class SendScreen extends StatelessWidget {
  const SendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addressController = TextEditingController();
    final amountController = TextEditingController();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Send"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 Address Field
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.black),

              decoration: InputDecoration(
                labelText: "Recipient Address",

                filled: true,
                fillColor: Colors.grey.shade100,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Amount Field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),

              decoration: InputDecoration(
                labelText: "Amount",

                filled: true,
                fillColor: Colors.grey.shade100,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            // 🔥 Send Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Transaction sent (demo)")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}