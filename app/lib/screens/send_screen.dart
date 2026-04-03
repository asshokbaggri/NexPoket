import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/storage_service.dart';

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

  final String rpcUrl =
      "https://mainnet.infura.io/v3/339315f5c81347debe3b12374712fa4d";

  Future<void> sendTransaction() async {
    final toAddress = addressController.text.trim();
    final amountText = amountController.text.trim();

    if (toAddress.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    double amountEth;
    try {
      amountEth = double.parse(amountText);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔥 FIXED
      final privateKey =
          await StorageService.getPrivateKey(widget.walletAddress);

      if (privateKey == null) {
        throw Exception("Wallet not found");
      }

      final client = Web3Client(rpcUrl, Client());
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

      // 🔥 GAS
      final gasPrice = await client.getGasPrice();

      BigInt gasLimit;
      try {
        gasLimit = await client.estimateGas(
          sender: senderAddress,
          to: receiver,
          value: EtherAmount.fromUnitAndValue(
            EtherUnit.ether,
            amountEth,
          ),
        );
      } catch (_) {
        gasLimit = BigInt.from(21000);
      }

      final gasCostWei = gasPrice.getInWei * gasLimit;
      final gasCostEth =
          EtherAmount.inWei(gasCostWei).getValueInUnit(EtherUnit.ether);

      final totalNeeded = amountEth + gasCostEth;

      if (balanceEth < totalNeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Insufficient Balance\nNeed: ${totalNeeded.toStringAsFixed(6)} ETH\nHave: ${balanceEth.toStringAsFixed(6)} ETH",
            ),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // 🚀 SEND
      final txHash = await client.sendTransaction(
        credentials,
        Transaction(
          to: receiver,
          value: EtherAmount.fromUnitAndValue(
            EtherUnit.ether,
            amountEth,
          ),
          gasPrice: gasPrice,
          maxGas: gasLimit.toInt(),
        ),
        chainId: 1,
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
      appBar: AppBar(title: const Text("Send")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 FROM
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

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: "Amount (ETH)",
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