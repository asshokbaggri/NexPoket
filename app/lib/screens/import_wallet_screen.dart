import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bip39/bip39.dart' as bip39;

import '../core/wallet_service.dart';
import '../core/app_shell.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {

  final controller = TextEditingController();

  List<String> wordList = [];
  List<String> suggestions = [];

  @override
  void initState() {
    super.initState();
    loadWordList();
  }

  // 🔥 LOAD FULL 2048 WORDLIST
  Future<void> loadWordList() async {
    final data = await rootBundle.loadString('assets/bip39_english.txt');

    setState(() {
      wordList = data.split('\n');
    });
  }

  // 🔥 SMART SUGGESTIONS
  void updateSuggestions(String input) {
    final words = input.trim().split(" ");
    final lastWord = words.isNotEmpty ? words.last : "";

    if (lastWord.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final matches = wordList
        .where((word) => word.startsWith(lastWord))
        .take(6)
        .toList();

    setState(() => suggestions = matches);
  }

  // 🔥 SELECT SUGGESTION
  void selectSuggestion(String word) {
    final words = controller.text.trim().split(" ");

    if (words.isNotEmpty) {
      words.removeLast();
    }

    words.add(word);

    controller.text = words.join(" ") + " ";

    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    setState(() => suggestions = []);
  }

  // 🔥 PASTE
  Future<void> pastePhrase() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null && data.text != null) {
      controller.text = data.text!.trim();
      updateSuggestions(controller.text);
    }
  }

  // 🔥 IMPORT WALLET
  Future<void> importWallet() async {
    final mnemonic = controller.text.trim();

    if (!bip39.validateMnemonic(mnemonic)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Seed Phrase")),
      );
      return;
    }

    final wallet = await WalletService.createWallet(mnemonic);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => AppShell(
          walletAddress: wallet["address"]!,
          network: "BSC", // DEFAULT FIX
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Import Wallet"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔥 INPUT BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                onChanged: updateSuggestions,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: const InputDecoration(
                  hintText: "Enter or paste recovery phrase",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔥 SUGGESTIONS (PRO UI)
            if (suggestions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions.map((word) {
                    return GestureDetector(
                      onTap: () => selectSuggestion(word),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3375BB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(
                            color: Color(0xFF3375BB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            // 🔥 PASTE BUTTON (IMPROVED)
            OutlinedButton.icon(
              onPressed: pastePhrase,
              icon: const Icon(Icons.paste),
              label: const Text("Paste from Clipboard"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const Spacer(),

            // 🔥 IMPORT BUTTON
            ElevatedButton(
              onPressed: importWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text(
                "Import Wallet",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}