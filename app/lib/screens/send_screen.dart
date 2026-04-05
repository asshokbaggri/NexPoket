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

  int chainId = 56;

  List<Map<String, dynamic>> tokens = [];
  Map<String, dynamic>? selectedToken;

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

      final receiver = EthereumAddress.fromHex(toAddress);

      // 🔥 NATIVE TOKEN ONLY (ERC20 NEXT STEP)
      if (selectedToken!["type"] == "native") {

        final balance = await client.getBalance(senderAddress);
        final balanceEth = balance.getValueInUnit(EtherUnit.ether);

        final gasPrice = await client.getGasPrice();

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

        final gasCostWei = gasPrice.getInWei * gasLimit;
        final gasCostEth =
            EtherAmount.inWei(gasCostWei).getValueInUnit(EtherUnit.ether);

        final totalNeeded = amount + gasCostEth;

        if (balanceEth < totalNeeded) {
          throw Exception("Insufficient balance");
        }

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
      } else {
        throw Exception("Token transfer coming next update 🚀");
      }

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

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Recipient Address",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: openScanner,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount ($symbol)",
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
                  : const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}