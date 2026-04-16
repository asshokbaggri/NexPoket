import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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
  bool isInitializing = true;

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

  // ============================
  // 🔥 INIT NETWORK + BALANCE
  // ============================

  Future<void> initNetwork() async {

    final net = await StorageService.getSelectedNetwork();

    final defaultTokens = WalletService.getDefaultTokens(net);
    final customTokens = await StorageService.getTokens(net);

    final allTokens = [...defaultTokens, ...customTokens];

    double balValue = 0;

    final firstToken = allTokens.first;

    if (firstToken["isNative"] == true) {
      final bal = await WalletService.getBalance(
        widget.walletAddress,
        net,
      );
      balValue = double.tryParse(bal) ?? 0;
    } else {
      final bal = await WalletService.getTokenBalance(
        address: widget.walletAddress,
        contract: firstToken["contract"],
        decimals: firstToken["decimals"],
        network: net,
      );
      balValue = double.tryParse(bal) ?? 0;
    }

    setState(() {
      selectedNetwork = net;
      tokens = allTokens;
      selectedToken = firstToken;

      symbol = selectedToken!["symbol"];
      chainId = getChainId(net);
      currentBalance = balValue;

      isInitializing = false;
    });
  }

  int getChainId(String network) {
    switch (network) {
      case "Ethereum": return 1;
      case "Polygon": return 137;
      case "BSC":
      default: return 56;
    }
  }

  // ============================
  // 🔥 SMART MAX
  // ============================

  void setMaxAmount() {
    if (currentBalance <= 0) return;

    final isNative = selectedToken?["isNative"] == true;

    double max = currentBalance;

    if (isNative) {
      max = currentBalance * 0.95;
    }

    amountController.text = max.toStringAsFixed(6);
  }

  Future<void> pasteAddress() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      addressController.text = data.text ?? "";
    }
  }

  // ============================
  // 🔥 MAIN TRANSACTION ENGINE
  // ============================

  Future<void> sendTransaction() async {

    final toAddress = addressController.text.trim();
    final amountText = amountController.text.trim();

    if (toAddress.isEmpty || amountText.isEmpty) {
      showMsg("Fill all fields");
      return;
    }

    if (!toAddress.startsWith("0x") || toAddress.length != 42) {
      showMsg("Invalid address");
      return;
    }

    double amount;
    try {
      amount = double.parse(amountText);
    } catch (_) {
      showMsg("Invalid amount");
      return;
    }

    if (amount <= 0) {
      showMsg("Amount must be greater than 0");
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

      final isNative = selectedToken?["isNative"] == true;

      String txHash;

      // ============================
      // 🔥 NATIVE TRANSFER FIXED
      // ============================
      if (isNative) {

        final amountInWei = BigInt.parse(
          (amount * pow(10, 18)).toStringAsFixed(0),
        );

        txHash = await client.sendTransaction(
          credentials,
          Transaction(
            to: receiver,
            value: EtherAmount.inWei(amountInWei),
          ),
          chainId: chainId,
        );

      } else {

        // ============================
        // 🔥 ERC20 TRANSFER FIXED
        // ============================

        final contractAddress =
            EthereumAddress.fromHex(selectedToken!["contract"]);

        final abi = ContractAbi.fromJson(
          '''
          [
            {
              "constant": false,
              "inputs": [
                {"name": "_to","type": "address"},
                {"name": "_value","type": "uint256"}
              ],
              "name": "transfer",
              "outputs": [{"name": "","type": "bool"}],
              "type": "function"
            }
          ]
          ''',
          "ERC20",
        );

        final contract = DeployedContract(abi, contractAddress);

        final decimals =
            int.tryParse(selectedToken!["decimals"].toString()) ?? 18;

        final amountInWei = BigInt.parse(
          (amount * pow(10, decimals)).toStringAsFixed(0),
        );

        final tx = Transaction.callContract(
          contract: contract,
          function: contract.function("transfer"),
          parameters: [receiver, amountInWei],
        );

        txHash = await client.sendTransaction(
          credentials,
          tx,
          chainId: chainId,
        );
      }

      showMsg("TX Sent ✔\n$txHash");

      Navigator.pop(context);

    } catch (e) {
      showMsg(e.toString());
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ============================
  // 🔥 TOKEN SELECTOR FIXED
  // ============================

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
        onChanged: (val) async {
          if (val == null) return;

          double balValue = 0;

          if (val["isNative"] == true) {
            final bal = await WalletService.getBalance(
              widget.walletAddress,
              selectedNetwork,
            );
            balValue = double.tryParse(bal) ?? 0;
          } else {
            final bal = await WalletService.getTokenBalance(
              address: widget.walletAddress,
              contract: val["contract"],
              decimals: val["decimals"],
              network: selectedNetwork,
            );
            balValue = double.tryParse(bal) ?? 0;
          }

          setState(() {
            selectedToken = val;
            symbol = val["symbol"];
            currentBalance = balValue;
          });
        },
      ),
    );
  }

  // ============================
  // UI
  // ============================

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

  @override
  Widget build(BuildContext context) {

    if (isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                        child: Text("Paste",
                          style: TextStyle(color: Color(0xFF3375BB)),
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

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount ($symbol)",
                suffixIcon: GestureDetector(
                  onTap: setMaxAmount,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Text("Max",
                      style: TextStyle(color: Color(0xFF3375BB)),
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