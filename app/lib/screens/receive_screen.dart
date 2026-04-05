import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/storage_service.dart';
import '../core/wallet_service.dart';

class ReceiveScreen extends StatefulWidget {
  final String walletAddress;

  const ReceiveScreen({super.key, required this.walletAddress});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {

  String selectedNetwork = "BSC";

  List<Map<String, dynamic>> tokens = [];
  Map<String, dynamic>? selectedToken;

  String symbol = "BNB";

  @override
  void initState() {
    super.initState();
    initNetwork();
  }

  Future<void> initNetwork() async {

    final net = await StorageService.getSelectedNetwork();

    final defaultTokens = WalletService.getDefaultTokens(net);
    final customTokens = await StorageService.getTokens(net);

    final allTokens = [...defaultTokens, ...customTokens];

    setState(() {
      selectedNetwork = net;
      tokens = allTokens;
      selectedToken = allTokens.first;
      symbol = selectedToken!["symbol"];
    });
  }

  void copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.walletAddress));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address copied ✔")),
    );
  }

  void shareAddress() {
    Share.share(
      "My $selectedNetwork ($symbol) Wallet Address:\n\n${widget.walletAddress}",
    );
  }

  String getNetworkDisplayName() {
    switch (selectedNetwork) {
      case "Ethereum":
        return "Ethereum (ETH)";
      case "Polygon":
        return "Polygon (POL)";
      case "BSC":
      default:
        return "BNB Smart Chain (BNB)";
    }
  }

  Widget buildTokenSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3375BB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<Map<String, dynamic>>(
        value: selectedToken,
        underline: const SizedBox(),
        items: tokens.map((t) {
          return DropdownMenuItem(
            value: t,
            child: Text("${t["symbol"]}"),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null) return;

          setState(() {
            selectedToken = val;
            symbol = val["symbol"];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text("Receive ($symbol)"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 10),

            // 🔥 NETWORK + TOKEN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildTokenSelector(),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getNetworkDisplayName(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 🔥 QR CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                  )
                ],
              ),
              child: QrImageView(
                data: widget.walletAddress,
                version: QrVersions.auto,
                size: 220,
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 ADDRESS BOX
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.walletAddress,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 ACTION BUTTONS
            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => copyAddress(context),
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text(
                      "Copy",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3375BB),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: shareAddress,
                    icon: const Icon(Icons.share, color: Color(0xFF3375BB)),
                    label: const Text(
                      "Share",
                      style: TextStyle(color: Color(0xFF3375BB)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3375BB)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔥 WARNING
            Text(
              "Send only $symbol ($selectedNetwork) assets to this address.\nSending other assets may result in permanent loss.",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}