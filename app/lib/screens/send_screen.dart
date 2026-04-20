// app/lib/screens/send_screen.dart

import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../core/storage_service.dart';
import '../core/wallet_service.dart';
import 'transaction_preview_screen.dart';

class SendScreen extends StatefulWidget {
  final String walletAddress;

  final Map<String, dynamic>? initialToken;
  

  const SendScreen({
    super.key,
    required this.walletAddress,
    this.initialToken,
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

  String selectedTokenKey = "";

  double currentBalance = 0;

  Map<String, double> balanceCache = {};

  // 🔥 NEW VALIDATION STATE
  String errorText = "";
  bool isValid = false;

  @override
  void initState() {
    super.initState();
    initNetwork();
  }

  // ============================
  // 🔥 TOKEN KEY
  // ============================

  String getTokenKey(Map<String, dynamic> t) {
    final contract = (t["contract"] ?? "").toString().toLowerCase();
    return "${t["symbol"]}_$contract";
  }

  Map<String, dynamic> get currentToken {
    return tokens.firstWhere(
      (t) => getTokenKey(t) == selectedTokenKey,
    );
  }

  // ============================
  // 🔥 VALIDATION
  // ============================

  void validateInput() {
    final address = addressController.text.trim();
    final amountText = amountController.text.trim();

    double amount = double.tryParse(amountText) ?? 0;

    String error = "";

    if (address.isEmpty || amountText.isEmpty) {
      error = "";
    } else if (!address.startsWith("0x") || address.length != 42) {
      error = "Invalid address";
    } else if (amount <= 0) {
      error = "Invalid amount";
    } else if (amount > currentBalance) {
      error = "Insufficient Balance";
    }

    setState(() {
      errorText = error;
      isValid = error.isEmpty &&
          address.isNotEmpty &&
          amountText.isNotEmpty;
    });
  }

  // ============================
  // 🔥 BALANCE
  // ============================

  Future<double> getTokenBalanceFast(Map<String, dynamic> token) async {

    final key = getTokenKey(token);

    if (balanceCache.containsKey(key)) {
      return balanceCache[key]!;
    }

    double balValue = 0;

    final tokenNetwork = token["network"] ?? selectedNetwork;

    final isNative = token["isNative"] == true;
    final decimals = int.tryParse(token["decimals"].toString()) ?? 18;

    if (isNative) {
      final bal = await WalletService.getBalance(
        widget.walletAddress,
        tokenNetwork,
      );
      balValue = double.tryParse(bal) ?? 0;
    } else {
      final bal = await WalletService.getTokenBalance(
        address: widget.walletAddress,
        contract: token["contract"],
        decimals: decimals,
        network: tokenNetwork,
      );
      balValue = double.tryParse(bal) ?? 0;
    }

    balanceCache[key] = balValue;
    return balValue;
  }

  // ============================
  // 🔥 INIT
  // ============================

  Future<void> initNetwork() async {

    final net = await StorageService.getSelectedNetwork();

    final defaultTokens = WalletService.getDefaultTokens(net);
    final customTokens = await StorageService.getTokens(net);

    final allTokens = [...defaultTokens, ...customTokens];

    Map<String, dynamic> selected = allTokens.first;

    // 🔥 IF TOKEN COMES FROM TOKEN DETAIL SCREEN
    if (widget.initialToken != null) {
      final found = allTokens.where((t) {

        final tContract = (t["contract"] ?? "").toString().toLowerCase();
        final iContract = (widget.initialToken!["contract"] ?? "")
            .toString()
            .toLowerCase();

        return t["symbol"] == widget.initialToken!["symbol"] &&
            tContract == iContract;
      });

      if (found.isNotEmpty) {
        selected = found.first;
      }
    }

    final balValue = await getTokenBalanceFast(selected);

    setState(() {
      selectedNetwork = net;
      tokens = allTokens;

      selectedTokenKey = getTokenKey(selected);
      symbol = selected["symbol"];

      chainId = getChainId(net);
      currentBalance = balValue;

      isInitializing = false;
    });

    setState(() {
      selectedNetwork = net;
      tokens = allTokens;

      selectedTokenKey = getTokenKey(selected);
      symbol = selected["symbol"];

      chainId = getChainId(net);
      currentBalance = balValue;

      isInitializing = false;
    });

    validateInput();
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
  // 🔥 MAX
  // ============================

  void setMaxAmount() {
    if (currentBalance <= 0) return;

    final isNative = currentToken["isNative"] == true;

    double max = currentBalance;

    if (isNative) {
      max = currentBalance * 0.95;
    }

    amountController.text = max.toStringAsFixed(6);
    validateInput();
  }

  Future<void> pasteAddress() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      addressController.text = data.text ?? "";
      validateInput();
    }
  }

  // ============================
  // 🔥 SEND
  // ============================

  Future<void> sendTransaction() async {

    final toAddress = addressController.text.trim();
    final amountText = amountController.text.trim();

    double amount = double.parse(amountText);

    setState(() => isLoading = true);

    try {
      final privateKey =
          await StorageService.getPrivateKey(widget.walletAddress);

      final rpc = WalletService.networks[selectedNetwork]!["rpc"]!;
      final client = Web3Client(rpc, Client());

      final credentials = EthPrivateKey.fromHex(privateKey!);
      final receiver = EthereumAddress.fromHex(toAddress);

      final token = currentToken;
      final isNative = token["isNative"] == true;

      String txHash;

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

        final contractAddress =
            EthereumAddress.fromHex(token["contract"]);

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
            int.tryParse(token["decimals"].toString()) ?? 18;

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
  // 🔥 TOKEN SELECTOR
  // ============================

  Widget buildTokenSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: DropdownButton<String>(
        value: selectedTokenKey,
        isExpanded: true,
        underline: const SizedBox(),
        items: tokens.map((t) {

          final key = getTokenKey(t);
          final iconPath =
              WalletService.resolveLocalIcon(t["symbol"]);

          return DropdownMenuItem<String>(
            value: key,
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
        onChanged: (key) async {
          if (key == null) return;

          final token = tokens.firstWhere(
            (t) => getTokenKey(t) == key,
          );

          setState(() {
            selectedTokenKey = key;
            symbol = token["symbol"];
            currentBalance = 0;

            // 🔥 RESET
            amountController.clear();
            addressController.clear();
            errorText = "";
            isValid = false;
          });

          final balValue = await getTokenBalanceFast(token);

          if (!mounted) return;

          setState(() {
            currentBalance = balValue;
          });

          validateInput();
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
                validateInput();

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
              onChanged: (_) => validateInput(),
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
              onChanged: (_) => validateInput(),
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

            if (errorText.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errorText,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: (isLoading || !isValid)
                  ? null
                  : () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionPreviewScreen(
                            toAddress: addressController.text.trim(),
                            amount: amountController.text.trim(),
                            symbol: symbol,
                            network: selectedNetwork,
                            onConfirm: () {
                              Navigator.pop(context);
                              sendTransaction();
                            },
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}