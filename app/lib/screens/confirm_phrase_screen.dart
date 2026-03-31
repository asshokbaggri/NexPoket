import 'package:flutter/material.dart';
import '../core/app_shell.dart';

class ConfirmPhraseScreen extends StatefulWidget {
  final List<String> seedWords;
  final String walletAddress;

  const ConfirmPhraseScreen({
    super.key,
    required this.seedWords,
    required this.walletAddress,
  });

  @override
  State<ConfirmPhraseScreen> createState() => _ConfirmPhraseScreenState();
}

class _ConfirmPhraseScreenState extends State<ConfirmPhraseScreen> {

  late List<String> correctWords;
  late List<String> shuffledWords;

  List<String> selectedWords = [];

  @override
  void initState() {
    super.initState();

    correctWords = widget.seedWords;
    shuffledWords = List.from(correctWords)..shuffle();
  }

  void selectWord(String word) {
    if (!selectedWords.contains(word) &&
        selectedWords.length < correctWords.length) {
      setState(() {
        selectedWords.add(word);
      });
    }
  }

  void removeLastWord() {
    if (selectedWords.isNotEmpty) {
      setState(() {
        selectedWords.removeLast();
      });
    }
  }

  bool isCorrect() {
    return selectedWords.join(" ") == correctWords.join(" ");
  }

  @override
  Widget build(BuildContext context) {
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

            // 🔥 NUMBERED BOX GRID
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    word.isEmpty
                        ? "${index + 1}."
                        : "${index + 1}. $word",
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: removeLastWord,
                icon: const Icon(Icons.backspace),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: shuffledWords.map((word) {

                  final isUsed = selectedWords.contains(word);

                  return ElevatedButton(
                    onPressed: isUsed ? null : () => selectWord(word),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isUsed ? Colors.grey.shade300 : Colors.white,
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 FIXED NAVIGATION
            ElevatedButton(
              onPressed: isCorrect()
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppShell(
                            walletAddress: widget.walletAddress, // ✅ FIX
                          ),
                        ),
                      );
                    }
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