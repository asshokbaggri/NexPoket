// app/lib/screens/transaction_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/wallet_service.dart';
import '../core/storage_service.dart';

class TransactionPreviewScreen extends StatefulWidget {
  final String toAddress;
  final String amount;
  final String symbol;
  final String network;
  final VoidCallback onConfirm;

  const TransactionPreviewScreen({
    super.key,
    required this.toAddress,
    required this.amount,
    required this.symbol,
    required this.network,
    required this.onConfirm,
  });

  @override
  State<TransactionPreviewScreen> createState() =>
      _TransactionPreviewScreenState();
}

class _TransactionPreviewScreenState
    extends State<TransactionPreviewScreen> {

  bool isLoading = true;

  double gasFee = 0;
  double total = 0;

  double tokenPrice = 0;
  double gasUsd = 0;
  double totalUsd = 0;

  String walletName = "";
  String walletAddress = "";

  @override
  void initState() {
    super.initState();
    initAll();
  }

  // ============================
  // 🔥 INIT ALL
  // ============================

  Future<void> initAll() async {
    await loadWallet();
    await estimateGas();
    await loadPrices();
  }

  // ============================
  // 🔥 LOAD WALLET INFO
  // ============================

  Future<void> loadWallet() async {
    final wallet = await StorageService.getSelectedWallet();

    if (wallet != null) {
      walletName = wallet["name"] ?? "Wallet";
      walletAddress = wallet["address"] ?? "";
    }
  }

  // ============================
  // 🔥 SMART NETWORK NAME
  // ============================

  String getDisplayNetworkName(String net) {
    switch (net) {
      case "BSC":
        return "BNB Smart Chain";
      case "Ethereum":
        return "Ethereum Mainnet";
      case "Polygon":
        return "Polygon Network";
      default:
        return net;
    }
  }

  // ============================
  // 🔥 RPC
  // ============================

  String getRpc() {
    return WalletService.networks[widget.network]!["rpc"]!;
  }

  // ============================
  // 🔥 GAS ESTIMATION
  // ============================

  Future<void> estimateGas() async {
    try {
      final client = Web3Client(getRpc(), Client());

      final gasPrice = await client.getGasPrice();

      int gasLimit = 21000;

      if (widget.symbol.toLowerCase() !=
          WalletService.getSymbol(widget.network).toLowerCase()) {
        gasLimit = 65000;
      }

      final gasInWei =
          gasPrice.getInWei * BigInt.from(gasLimit);

      final feeEth =
          gasInWei / BigInt.from(10).pow(18);

      gasFee = double.tryParse(feeEth.toString()) ?? 0;

      total = double.parse(widget.amount) + gasFee;

      client.dispose();

    } catch (_) {
      gasFee = 0.0003;
      total = double.parse(widget.amount) + gasFee;
    }
  }

  // ============================
  // 🔥 PRICE FETCH
  // ============================

  Future<void> loadPrices() async {
    try {
      final prices =
          await WalletService.getLivePricesAdvanced([
        {"symbol": widget.symbol, "contract": ""}
      ], widget.network);

      tokenPrice =
          prices[widget.symbol]?["price"] ?? 0;

      gasUsd = gasFee * tokenPrice;
      totalUsd = total * tokenPrice;

    } catch (_) {}

    setState(() {
      isLoading = false;
    });
  }

  // ============================
  // 🔥 TOKEN ICON
  // ============================

  Widget buildTokenIcon() {
    final local =
        WalletService.resolveLocalIcon(widget.symbol);

    final fallback =
        WalletService.resolveFallbackIcon(
      network: widget.network,
      contract: "",
      isNative: true,
    );

    return SizedBox(
      width: 60,
      height: 60,
      child: SvgPicture.asset(
        local,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Image.network(
            fallback,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.currency_bitcoin, size: 50),
          );
        },
      ),
    );
  }

  // ============================
  // 🔥 SHORT ADDRESS
  // ============================

  String shortAddress(String addr) {
    if (addr.length < 10) return addr;
    return "${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}";
  }

  // ============================
  // UI
  // ============================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Transaction"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  // 🔥 TOP ICON + AMOUNT
                  Column(
                    children: [

                      buildTokenIcon(),

                      const SizedBox(height: 12),

                      Text(
                        "${widget.amount} ${widget.symbol}",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "\$${(double.parse(widget.amount) * tokenPrice).toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 🔥 DETAILS CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                    ),
                    child: Column(
                      children: [

                        // FROM
                        _rowCustom(
                          icon: Icons.account_balance_wallet,
                          label: "From",
                          value: "$walletName\n${shortAddress(walletAddress)}",
                        ),

                        // TO
                        _rowCustom(
                          icon: Icons.person,
                          label: "To",
                          value: shortAddress(widget.toAddress),
                        ),

                        // NETWORK (🔥 FIXED)
                        _rowCustom(
                          icon: Icons.account_tree,
                          label: "Network",
                          value: getDisplayNetworkName(widget.network),
                        ),

                        const Divider(height: 25),

                        // GAS
                        _rowCustom(
                          icon: Icons.local_gas_station,
                          label: "Gas Fee",
                          value:
                              "${gasFee.toStringAsFixed(6)} ${WalletService.getSymbol(widget.network)}\n\$${gasUsd.toStringAsFixed(4)}",
                        ),

                        // TOTAL
                        _rowCustom(
                          icon: Icons.calculate,
                          label: "Total",
                          value:
                              "${total.toStringAsFixed(6)} ${WalletService.getSymbol(widget.network)}\n\$${totalUsd.toStringAsFixed(4)}",
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 🔥 CONFIRM BUTTON
                  ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3375BB),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Confirm & Send",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============================
  // 🔥 CUSTOM ROW
  // ============================

  Widget _rowCustom({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(icon, size: 20, color: Colors.grey),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}