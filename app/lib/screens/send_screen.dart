// app/lib/screens/send_screen.dart

import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../core/storage_service.dart';
import '../core/wallet_service.dart';

class SendScreen extends StatefulWidget {
  final String walletAddress;

  const SendScreen({
    super.key,
    required this.walletAddress,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {

  final addressController = TextEditingController();
  final amountController = TextEditingController();

  bool isLoading = false;
  bool isScanning = false;
  bool isInitializing = true; // 🔥 FIX

  String selectedNetwork = "BSC";
  String symbol = "BNB";

  int chainId = 56;

  List<Map<String, dynamic>> tokens = [];
  Map<String, dynamic>? selectedToken;

  double currentBalance = 0;

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

    final bal = await WalletService.getBalance(
      widget.walletAddress,
      net,
    );

    setState(() {
      selectedNetwork = net;
      tokens = allTokens;
      selectedToken = allTokens.first;

      symbol = selectedToken!["symbol"];
      chainId = getChainId(net);
      currentBalance = double.tryParse(bal) ?? 0;

      isInitializing = false; // 🔥 IMPORTANT
    });
  }

  int getChainId(String network) {
    switch (network) {
      case "Ethereum":
        return 1;
      case "Polygon":
        return 137;
      case "BSC":
      default:
        return 56;
    }
  }

  void setMaxAmount() {
    if (currentBalance <= 0) return;
    final max = currentBalance * 0.98;
    amountController.text = max.toStringAsFixed(6);
  }

  Future<void> pasteAddress() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      addressController.text = data.text ?? "";
    }
  }

  Future<void> sendTransaction() async {

    final toAddress = addressController.text.trim();
    final amountText = amountController.text.trim();

    if (toAddress.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    double amount;
    try {
      amount = double.parse(amountText);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final privateKey =
          await StorageService.getPrivateKey(widget.walletAddress);

      final rpc = WalletService.networks[selectedNetwork]!["rpc"]!;
      final client = Web3Client(rpc, Client());

      final credentials = EthPrivateKey.fromHex(privateKey!);
      final receiver = EthereumAddress.fromHex(toAddress);

      final txHash = await client.sendTransaction(
        credentials,
        Transaction(
          to: receiver,
          value: EtherAmount.fromUnitAndValue(
            EtherUnit.ether,
            amount,
          ),
        ),
        chainId: chainId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("TX Sent: $txHash")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  void openScanner() {
    isScanning = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Scan QR")),
          body: MobileScanner(
            onDetect: (barcodeCapture) {
              if (isScanning) return;

              final code = barcodeCapture.barcodes.first.rawValue;

              if (code != null) {
                isScanning = true;
                addressController.text = code;

                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.pop(context);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildTokenSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: DropdownButton<Map<String, dynamic>>(
        value: selectedToken,
        isExpanded: true,
        underline: const SizedBox(),
        items: tokens.map((t) {

          final iconPath =
              WalletService.resolveLocalIcon(t["symbol"]);

          return DropdownMenuItem(
            value: t,
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.currency_bitcoin),
                ),
                const SizedBox(width: 10),
                Text("${t["symbol"]}"),
              ],
            ),
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

    if (isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Send ($symbol)"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            buildTokenSelector(),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.walletAddress,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 ADDRESS INPUT (FIXED BUTTON STYLE)
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Recipient Address",
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    GestureDetector(
                      onTap: pasteAddress,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "Paste",
                          style: TextStyle(
                            color: Color(0xFF3375BB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: openScanner,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 AMOUNT INPUT (FIXED BUTTON STYLE)
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount ($symbol)",
                suffixIcon: GestureDetector(
                  onTap: setMaxAmount,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Text(
                      "Max",
                      style: TextStyle(
                        color: Color(0xFF3375BB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Balance: ${currentBalance.toStringAsFixed(6)} $symbol",
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: isLoading ? null : sendTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Send",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
