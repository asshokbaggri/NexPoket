import 'package:flutter/material.dart';
import '../core/app_shell.dart';

class ConfirmPhraseScreen extends StatefulWidget {
  const ConfirmPhraseScreen({super.key});

  @override
  State<ConfirmPhraseScreen> createState() => _ConfirmPhraseScreenState();
}

class _ConfirmPhraseScreenState extends State<ConfirmPhraseScreen> {

  final List<String> correctWords = [
    "apple", "banana", "cat", "dog",
    "eagle", "fish", "grape", "hat",
    "ice", "joker", "kite", "lion"
  ];

  late List<String> shuffledWords;
  List<String> selectedWords = [];

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(correctWords)..shuffle();
  }

  void selectWord(String word) {
    if (!selectedWords.contains(word)) {
      setState(() {
        selectedWords.add(word);
      });
    }
  }

  void removeWord(String word) {
    setState(() {
      selectedWords.remove(word);
    });
  }

  bool isCorrect() {
    return selectedWords.join(" ") == correctWords.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text("Confirm Phrase"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Tap the words in the correct order.",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            // 🔹 Selected words
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedWords.map((word) {
                return GestureDetector(
                  onTap: () => removeWord(word),
                  child: Chip(
                    label: Text(word),
                    backgroundColor: Colors.deepPurple,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Divider(color: Colors.white24),

            const SizedBox(height: 20),

            // 🔹 Options
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: shuffledWords.map((word) {
                  return ElevatedButton(
                    onPressed: () => selectWord(word),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C2E),
                    ),
                    child: Text(word),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 Continue
            ElevatedButton(
              onPressed: isCorrect()
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppShell(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}