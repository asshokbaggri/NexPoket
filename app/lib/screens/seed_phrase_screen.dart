import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Clipboard
import 'confirm_phrase_screen.dart';   // ✅ NEXT FLOW

class SeedPhraseScreen extends StatelessWidget {
  const SeedPhraseScreen({super.key});

  final List<String> _seedWords = const [
    "apple", "banana", "cat", "dog",
    "eagle", "fish", "grape", "hat",
    "ice", "joker", "kite", "lion"
  ];

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _seedWords.join(" ")));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recovery phrase copied")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Your Recovery Phrase"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Write down or copy these words in order and keep them safe.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            // 🔐 Seed Grid
            Expanded(
              child: GridView.builder(
                itemCount: _seedWords.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}. ${_seedWords[index]}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ⚠️ Warning
            const Text(
              "Never share your recovery phrase with anyone.",
              style: TextStyle(color: Colors.redAccent),
            ),

            const SizedBox(height: 20),

            // 📋 Copy Button
            ElevatedButton(
              onPressed: () => _copyToClipboard(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Copy Phrase"),
            ),

            const SizedBox(height: 10),

            // 🔥 Continue Button
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConfirmPhraseScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "I’ve Saved It",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}