import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 🔥 NEW

import '../core/storage_service.dart';
import '../core/wallet_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'seed_phrase_screen.dart';
import 'import_wallet_screen.dart';
import 'add_token_screen.dart';

class WalletHomeScreen extends StatefulWidget {
  final String walletAddress;
  final String network;

  const WalletHomeScreen({
    super.key,
    required this.walletAddress,
    required this.network,
  });

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {

  String walletName = "Wallet";
  String currentAddress = "";
  List<Map<String, dynamic>> wallets = [];

  String balance = "0.00";
  String symbol = "";
  bool isLoadingBalance = true;

  List<Map<String, dynamic>> tokens = [];
  Map<String, String> tokenBalances = {};
  bool isLoadingTokens = true;

  @override
  void initState() {
    super.initState();
    currentAddress = widget.walletAddress;
    initAll();
  }

  @override
  void didUpdateWidget(covariant WalletHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.network != widget.network ||
        oldWidget.walletAddress != widget.walletAddress) {

      currentAddress = widget.walletAddress;
      initAll();
    }
  }

  Future<void> initAll() async {
    await loadWallets();
    await loadBalance();
    await loadTokens();
  }

  Future<void> loadWallets() async {
    final data = await StorageService.getWallets();

    if (data.isEmpty) return;

    for (int i = 0; i < data.length; i++) {
      if (data[i]["name"] == null ||
          data[i]["name"].toString().trim().isEmpty) {
        data[i]["name"] = "Wallet ${i + 1}";
      }
    }

    final current = data.firstWhere(
      (w) => w["address"] == currentAddress,
      orElse: () => data.first,
    );

    setState(() {
      wallets = data;
      walletName = current["name"];
      currentAddress = current["address"];
    });
  }

  Future<void> loadBalance() async {
    setState(() => isLoadingBalance = true);

    try {
      final fetchedBalance = await WalletService.getBalance(
        currentAddress,
        widget.network,
      );

      final fetchedSymbol = WalletService.getSymbol(widget.network);

      if (!mounted) return;

      setState(() {
        balance = fetchedBalance;
        symbol = fetchedSymbol;
        isLoadingBalance = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        balance = "0.00";
        symbol = WalletService.getSymbol(widget.network);
        isLoadingBalance = false;
      });
    }
  }

  Future<void> loadTokens() async {

    setState(() => isLoadingTokens = true);

    try {
      final List<Map<String, dynamic>> defaultTokens =
          List<Map<String, dynamic>>.from(
              WalletService.getDefaultTokens(widget.network));

      final List<Map<String, dynamic>> customTokens =
          List<Map<String, dynamic>>.from(
              await StorageService.getTokensByNetwork(widget.network));

      final List<Map<String, dynamic>> merged = [
        ...defaultTokens,
        ...customTokens
      ];

      Map<String, String> balances = {};

      for (var token in merged) {

        try {
          String bal = "0.00";

          final isNative = token["isNative"] == true;
          final contract = token["contract"]?.toString() ?? "";

          if (isNative || contract.isEmpty) {
            bal = await WalletService.getBalance(
              currentAddress,
              widget.network,
            );
          } else {
            bal = await WalletService.getTokenBalance(
              address: currentAddress,
              contract: contract,
              decimals: int.tryParse(token["decimals"].toString()) ?? 18,
              network: widget.network,
            );
          }

          balances[token["symbol"]] = bal;

        } catch (e) {
          balances[token["symbol"]] = "0.00";
        }
      }

      if (!mounted) return;

      setState(() {
        tokens = merged;
        tokenBalances = balances;
        isLoadingTokens = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        tokens = [];
        tokenBalances = {};
        isLoadingTokens = false;
      });
    }
  }

  void copyAddress() {
    Clipboard.setData(ClipboardData(text: currentAddress));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address Copied ✔")),
    );
  }

  void switchWallet(String address) async {
    await StorageService.setSelectedWallet(address);

    setState(() {
      currentAddress = address;
    });

    await initAll();

    if (mounted) Navigator.pop(context);
  }

  void showWalletList() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: wallets.map((w) {
            final isActive = w["address"] == currentAddress;

            return ListTile(
              title: Text(
                w["name"],
                style: TextStyle(
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                w["address"],
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isActive
                  ? const Icon(Icons.check, color: Color(0xFF3375BB))
                  : null,
              onTap: () => switchWallet(w["address"]),
            );
          }).toList(),
        );
      },
    );
  }

  // 🔥 FINAL SVG ICON SYSTEM
  Widget buildTokenItem(Map<String, dynamic> token) {

    final symbol = (token["symbol"] ?? "").toString().toLowerCase();
    final iconPath = "assets/tokens/$symbol.svg";

    final bal = tokenBalances[token["symbol"]] ?? "0.00";

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: SvgPicture.asset(
            iconPath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,

            // 🔥 अगर SVG ना मिले तो fallback
            placeholderBuilder: (context) => const Icon(
              Icons.currency_bitcoin,
              color: Color(0xFF3375BB),
            ),
          ),
        ),
      ),

      title: Text(token["symbol"] ?? ""),
      subtitle: Text(token["name"] ?? ""),
      trailing: Text(bal),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SendScreen(
              walletAddress: currentAddress,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: showWalletList,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(walletName),
              const SizedBox(width: 5),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: initAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3375BB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Balance",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  isLoadingBalance
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "$balance $symbol",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      currentAddress,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: copyAddress,
                    child: const Icon(Icons.copy,
                        color: Color(0xFF3375BB)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                _actionButton(context, Icons.send, "Send", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SendScreen(walletAddress: currentAddress),
                    ),
                  );
                }),

                _actionButton(context, Icons.download, "Receive", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReceiveScreen(walletAddress: currentAddress),
                    ),
                  );
                }),

                _actionButton(context, Icons.add, "Buy", () {}),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Assets",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTokenScreen(
                          network: widget.network,
                        ),
                      ),
                    );

                    await loadTokens();
                  },
                  child: const Text("Add Crypto"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (isLoadingTokens)
              const Center(child: CircularProgressIndicator())
            else
              ...tokens.map((t) => buildTokenItem(t)).toList(),
          ],
        ),
      ),
    );
  }
}

Widget _actionButton(
  BuildContext context,
  IconData icon,
  String label,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF3375BB).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF3375BB)),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    ),
  );
}