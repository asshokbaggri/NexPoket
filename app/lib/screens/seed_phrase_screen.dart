// app/lib/screens/seed_phrase_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confirm_phrase_screen.dart';
import '../core/wallet_service.dart';

class SeedPhraseScreen extends StatefulWidget {

  final String? mnemonic; // 🔥 NEW
  final bool isBackup;    // 🔥 NEW

  const SeedPhraseScreen({
    super.key,
    this.mnemonic,
    this.isBackup = false,
  });

  @override
  State<SeedPhraseScreen> createState() => _SeedPhraseScreenState();
}

class _SeedPhraseScreenState extends State<SeedPhraseScreen> {

  late List<String> _seedWords;
  late String _mnemonic;

  @override
  void initState() {
    super.initState();

    // 🔥 FIX: HANDLE BOTH CASES (CREATE + BACKUP)
    if (widget.mnemonic != null && widget.mnemonic!.isNotEmpty) {
      _mnemonic = widget.mnemonic!;
    } else {
      _mnemonic = WalletService.generateMnemonic();
    }

    _seedWords = _mnemonic.split(" ");
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonic));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recovery phrase copied")),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          widget.isBackup
              ? "Backup Recovery Phrase"
              : "Your Recovery Phrase",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Text(
              widget.isBackup
                  ? "This is your wallet recovery phrase. Do NOT share it."
                  : "Write down or copy these words in order and keep them safe.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

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
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}. ${_seedWords[index]}",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),

            const Text(
              "Never share your recovery phrase with anyone.",
              style: TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _copyToClipboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Copy Phrase",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 DIFFERENT FLOW BASED ON TYPE
            if (!widget.isBackup)
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConfirmPhraseScreen(
                        seedWords: _seedWords,
                        mnemonic: _mnemonic,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "I’ve Saved It",
                  style: TextStyle(color: Colors.black),
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3375BB),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}