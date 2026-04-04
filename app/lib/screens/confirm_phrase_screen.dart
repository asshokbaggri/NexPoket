// app/lib/screens/confirm_phrase_screen.dart

import 'package:flutter/material.dart';
import '../core/app_shell.dart';
import '../core/wallet_service.dart';

class ConfirmPhraseScreen extends StatefulWidget {
  final List<String> seedWords;
  final String mnemonic;

  const ConfirmPhraseScreen({
    super.key,
    required this.seedWords,
    required this.mnemonic,
  });

  @override
  State<ConfirmPhraseScreen> createState() => _ConfirmPhraseScreenState();
}

class _ConfirmPhraseScreenState extends State<ConfirmPhraseScreen> {

  late List<String> correctWords;
  late List<Map<String, dynamic>> shuffledWords;

  List<String> selectedWords = [];

  @override
  void initState() {
    super.initState();

    correctWords = widget.seedWords;

    // 🔥 FIX: index-based shuffle (duplicate safe)
    shuffledWords = List.generate(correctWords.length, (i) {
      return {"word": correctWords[i], "used": false};
    })..shuffle();
  }

  void selectWord(int index) {
    if (selectedWords.length >= correctWords.length) return;

    if (!shuffledWords[index]["used"]) {
      setState(() {
        selectedWords.add(shuffledWords[index]["word"]);
        shuffledWords[index]["used"] = true;
      });
    }
  }

  void removeLastWord() {
    if (selectedWords.isEmpty) return;

    final lastWord = selectedWords.removeLast();

    // 🔥 find first used match
    for (var item in shuffledWords) {
      if (item["word"] == lastWord && item["used"] == true) {
        item["used"] = false;
        break;
      }
    }

    setState(() {});
  }

  bool isCorrect() {
    return selectedWords.join(" ") == correctWords.join(" ");
  }

  Future<void> completeWalletSetup() async {
    final wallet = await WalletService.createWallet(widget.mnemonic);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppShell(
          walletAddress: wallet["address"]!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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

            GridView.builder(
              shrinkWrap: true,
              itemCount: correctWords.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {

                final word = index < selectedWords.length
                    ? selectedWords[index]
                    : "";

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    word.isEmpty
                        ? "${index + 1}."
                        : "${index + 1}. $word",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: removeLastWord,
                icon: const Icon(Icons.backspace),
              ),
            ),

            const Divider(),

            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(shuffledWords.length, (index) {

                  final item = shuffledWords[index];

                  return ElevatedButton(
                    onPressed: item["used"]
                        ? null
                        : () => selectWord(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item["used"]
                          ? Colors.grey.shade300
                          : Colors.white,
                    ),
                    child: Text(
                      item["word"],
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isCorrect()
                  ? completeWalletSetup
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}