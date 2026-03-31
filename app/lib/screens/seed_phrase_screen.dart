import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confirm_phrase_screen.dart';
import '../core/wallet_service.dart';

class SeedPhraseScreen extends StatefulWidget {
  const SeedPhraseScreen({super.key});

  @override
  State<SeedPhraseScreen> createState() => _SeedPhraseScreenState();
}

class _SeedPhraseScreenState extends State<SeedPhraseScreen> {

  late List<String> _seedWords;
  late String _mnemonic;
  String? walletAddress;

  @override
  void initState() {
    super.initState();

    _mnemonic = WalletService.generateMnemonic();
    _seedWords = _mnemonic.split(" ");

    // 🔥 Create wallet
    WalletService.createWallet(_mnemonic).then((wallet) {
      setState(() {
        walletAddress = wallet["address"];
      });

      print("Wallet Address: $walletAddress");
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonic));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recovery phrase copied")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Your Recovery Phrase"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Write down or copy these words in order and keep them safe.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}. ${_seedWords[index]}",
                      style: const TextStyle(color: Colors.black),
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

            // 🔥 PASS REAL DATA
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConfirmPhraseScreen(
                      seedWords: _seedWords,
                      walletAddress: walletAddress ?? "",
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
            ),
          ],
        ),
      ),
    );
  }
}