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
      // ✅ Theme based
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Confirm Phrase"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Tap the words in the correct order.",
              style: TextStyle(color: Colors.grey),
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

                    backgroundColor: const Color(0xFF3375BB).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFF3375BB)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Divider(),

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
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.05),
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(color: Colors.black),
                    ),
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
                backgroundColor: const Color(0xFF3375BB),
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