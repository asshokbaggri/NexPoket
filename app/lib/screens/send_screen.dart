// app/lib/screens/send_screen.dart

import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  String selectedNetwork = "BSC";
  String symbol = "BNB";

  int chainId = 56; // default BSC

  @override
  void initState() {
    super.initState();
    initNetwork();
  }

  Future<void> initNetwork() async {
    final net = await StorageService.getSelectedNetwork();

    setState(() {
      selectedNetwork = net;
      symbol = WalletService.getSymbol(net);
      chainId = getChainId(net);
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

      if (privateKey == null) {
        throw Exception("Wallet not found");
      }

      final rpc = WalletService.networks[selectedNetwork]!["rpc"]!;

      final client = Web3Client(rpc, Client());

      final credentials = EthPrivateKey.fromHex(privateKey);
      final senderAddress = await credentials.extractAddress();

      EthereumAddress receiver;
      try {
        receiver = EthereumAddress.fromHex(toAddress);
      } catch (_) {
        throw Exception("Invalid recipient address");
      }

      // 🔥 BALANCE
      final balance = await client.getBalance(senderAddress);
      final balanceEth =
          balance.getValueInUnit(EtherUnit.ether);

      // 🔥 GAS PRICE
      final gasPrice = await client.getGasPrice();

      // 🔥 GAS LIMIT
      BigInt gasLimit;
      try {
        gasLimit = await client.estimateGas(
          sender: senderAddress,
          to: receiver,
          value: EtherAmount.fromUnitAndValue(
            EtherUnit.ether,
            amount,
          ),
        );
      } catch (_) {
        gasLimit = BigInt.from(21000);
      }

      // 🔥 GAS COST
      final gasCostWei = gasPrice.getInWei * gasLimit;
      final gasCostEth =
          EtherAmount.inWei(gasCostWei).getValueInUnit(EtherUnit.ether);

      final totalNeeded = amount + gasCostEth;

      if (balanceEth < totalNeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Insufficient Balance\nNeed: ${totalNeeded.toStringAsFixed(6)} $symbol\nHave: ${balanceEth.toStringAsFixed(6)} $symbol",
            ),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // 🚀 SEND TX
      final txHash = await client.sendTransaction(
        credentials,
        Transaction(
          to: receiver,
          value: EtherAmount.fromUnitAndValue(
            EtherUnit.ether,
            amount,
          ),
          gasPrice: gasPrice,
          maxGas: gasLimit.toInt(),
        ),
        chainId: chainId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("TX Sent: $txHash")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() => isLoading = false);
  }

  // 🔥 QR SCANNER
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

              final barcodes = barcodeCapture.barcodes;

              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;

                if (code != null) {
                  isScanning = true;

                  addressController.text = code;

                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.pop(context);
                  });
                }
              }
            },
          ),
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
        title: Text("Send ($symbol)"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 FROM ADDRESS
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
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 TO ADDRESS
            TextField(
              controller: addressController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: "Recipient Address",
                filled: true,
                fillColor:
                    isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: openScanner,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: "Amount ($symbol)",
                filled: true,
                fillColor:
                    isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: isLoading ? null : sendTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Transaction"),
            ),
          ],
        ),
      ),
    );
  }
}