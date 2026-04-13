// app/lib/screens/wallet_home_screen.dart

import 'dart:async'; // 🔥 ADDED

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/storage_service.dart';
import '../core/wallet_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'add_token_screen.dart';
import 'seed_phrase_screen.dart';
import 'import_wallet_screen.dart';
import 'token_detail_screen.dart';

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

  // 🔥 NEW
  Map<String, dynamic> livePrices = {};
  double totalPortfolio = 0;

  bool isPriceLoading = false; // 🔥 ADD THIS

  Timer? priceTimer; // 🔥 ADDED

  @override
  void initState() {
    super.initState();
    currentAddress = widget.walletAddress;
    initAll();

    // 🔥 AUTO REFRESH
    priceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return; // 🔥 IMPORTANT

      if (tokens.isNotEmpty) {
        loadPrices();
      }
    });
  }

  @override
  void dispose() {
    priceTimer?.cancel(); // 🔥 ADDED
    super.dispose();
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
    loadWallets();

    await Future.wait([
      loadBalance(),
      loadTokens(),
    ]);

    // ❌ REMOVE THIS BLOCK
    // loadPrices already called inside loadTokens
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
      final defaultTokens = List<Map<String, dynamic>>.from(
          WalletService.getDefaultTokens(widget.network));

      final customTokens = List<Map<String, dynamic>>.from(
          await StorageService.getTokensByNetwork(widget.network));

      final merged = [...defaultTokens, ...customTokens];

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

      // 🔥 IMPORTANT FIX
      await loadPrices();

    } catch (e) {
      if (!mounted) return;

      setState(() {
        tokens = [];
        tokenBalances = {};
        isLoadingTokens = false;
      });
    }
  }

  // 🔥 PRICE FORMAT FIX
  String formatPrice(double price) {
    if (price >= 1) {
      return "\$${price.toStringAsFixed(2)}";
    } else if (price >= 0.01) {
      return "\$${price.toStringAsFixed(4)}";
    } else {
      return "\$${price.toStringAsFixed(8)}";
    }
  }

  // 🔥 LIVE PRICE LOAD
  Future<void> loadPrices() async {

    if (isPriceLoading) return;
    isPriceLoading = true;

    try {

      final prices = await WalletService.getLivePricesAdvanced(
        tokens,
        widget.network,
      );

      final total = WalletService.calculatePortfolio(
        tokens,
        tokenBalances,
        prices,
      );

      if (!mounted) return;

      setState(() {
        livePrices = prices;
        totalPortfolio = total;
      });

    } catch (e) {
      // optional: log error
    } finally {
      // 🔥 ALWAYS RESET (MOST IMPORTANT)
      isPriceLoading = false;
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

    initAll();

    if (mounted) Navigator.pop(context);
  }

  void showWalletList() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: wallets.map((w) {
                    final isActive = w["address"] == currentAddress;

                    return ListTile(
                      title: Text(
                        w["name"],
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        w["address"],
                        overflow: TextOverflow.ellipsis,
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          if (isActive)
                            const Icon(Icons.check,
                                color: Color(0xFF3375BB)),

                          const SizedBox(width: 5),

                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              showWalletOptions(w);
                            },
                            child: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),

                      onTap: () => switchWallet(w["address"]),
                    );
                  }).toList(),
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.add,
                    color: Color(0xFF3375BB)),
                title: const Text("Add Wallet"),
                onTap: () {
                  Navigator.pop(context);
                  showAddWalletOptions();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showWalletOptions(Map<String, dynamic> wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 🔥 ADD THIS
      shape: const RoundedRectangleBorder( // 🔥 ADD THIS
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.55, // 🔥 ADD

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔥 HANDLE
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text("Wallet", style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 5),

              Text(
                wallet["name"],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit),
                title: const Text("Edit Wallet Name"),
                onTap: () {
                  Navigator.pop(context);
                  showRenameDialog(wallet);
                },
              ),

              const SizedBox(height: 10),

              const SizedBox(height: 25),

              const Text(
                "Secret phrase backups",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 15),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_outlined),
                title: const Text("Google Drive"),
                trailing: const Text(
                  "Back up now",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {},
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.touch_app_outlined),
                title: const Text("Manual"),
                trailing: const Text(
                  "Back up now",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showBackupWarning(wallet);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showAddWalletOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Add Wallet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF3375BB)),
                title: const Text("Create New Wallet"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SeedPhraseScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.download,
                    color: Color(0xFF3375BB)),
                title: const Text("Import Wallet"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImportWalletScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showRenameDialog(Map<String, dynamic> wallet) {

    final controller = TextEditingController(text: wallet["name"]);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Wallet Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter wallet name",
            ),
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {

                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                await StorageService.updateWalletName(
                  address: wallet["address"],
                  newName: newName,
                );

                Navigator.pop(context);
                initAll(); // 🔥 refresh UI

              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showBackupWarning(Map<String, dynamic> wallet) async {

    final mnemonic = await StorageService.getMnemonic(wallet["address"]);

    if (mnemonic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seed phrase not available")),
      );
      return;
    }

    bool c1 = false;
    bool c2 = false;
    bool c3 = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 🔥 ADD
      shape: const RoundedRectangleBorder( // 🔥 ADD
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              color: Colors.white, // 🔥 ADD THIS
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 50),

                  const SizedBox(height: 10),

                  const Text(
                    "This secret phrase unlocks your wallet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black, // 🔥 ADD
                    ),
                  ),

                  const SizedBox(height: 20),

                  CheckboxListTile(
                    value: c1,
                    onChanged: (v) => setState(() => c1 = v!),
                    activeColor: const Color(0xFF3375BB),
                    checkColor: Colors.white,
                    title: const Text(
                      "If I lose it, I will lose my funds.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87, // 🔥 FIX
                      ),
                    ),
                  ),

                  CheckboxListTile(
                    value: c2,
                    onChanged: (v) => setState(() => c2 = v!),
                    activeColor: const Color(0xFF3375BB),
                    checkColor: Colors.white,
                    title: const Text(
                        "If I share it, others can access my wallet.",
                        style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87, // 🔥 FIX
                      ),
                    ),
                  ),

                  CheckboxListTile(
                    value: c3,
                    onChanged: (v) => setState(() => c3 = v!),
                    activeColor: const Color(0xFF3375BB),
                    checkColor: Colors.white,
                    title: const Text(
                        "I understand and will keep it safe.",
                        style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87, // 🔥 FIX
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: (c1 && c2 && c3)
                        ? () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeedPhraseScreen(
                                  mnemonic: mnemonic,
                                  isBackup: true,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3375BB),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
               ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildTokenItem(Map<String, dynamic> token) {

    final symbol = (token["symbol"] ?? "").toString();

    final balance = double.tryParse(tokenBalances[symbol] ?? "0") ?? 0;

    final price = double.tryParse(
      livePrices[symbol]?["price"].toString() ?? "0",
    ) ?? 0;

    final change = double.tryParse(
      livePrices[symbol]?["change"].toString() ?? "0",
    ) ?? 0;

    final usdValue = balance * price;

    final localPath = WalletService.resolveLocalIcon(symbol);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),

      leading: CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: SvgPicture.asset(
            localPath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.currency_bitcoin),
          ),
        ),
      ),

      title: Text(
        symbol,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),

      subtitle: Row(
        children: [
          Text(formatPrice(price)),
          const SizedBox(width: 6),
          Text(
            "${change >= 0 ? "+" : ""}${change.toStringAsFixed(2)}%",
            style: TextStyle(
              color: change >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),

      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(balance.toStringAsFixed(6)),

          const SizedBox(height: 2),

          Text(
            "\$${usdValue.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokenDetailScreen(
              symbol: symbol,
              balance: balance,
              price: price,
              change: change,
              walletAddress: currentAddress,

              // 🔥 THIS IS THE MAIN FIX
              network: widget.network,
              contract: token["contract"] ?? "",
              isNative: token["isNative"] ?? false,
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
      body: RefreshIndicator(
        onRefresh: initAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            Row(
              children: [

                const SizedBox(width: 40),

                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: showWalletList,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              walletName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24), // 🔥 instead of "+"
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3375BB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Total Portfolio",
                      style: TextStyle(color: Colors.white70)),

                  const SizedBox(height: 8),

                  Text(
                    "\$${totalPortfolio.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "$balance $symbol",
                    style: const TextStyle(color: Colors.white70),
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
                    child: Text(currentAddress,
                        overflow: TextOverflow.ellipsis),
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddTokenScreen(network: widget.network),
                      ),
                    );
                    loadTokens();
                  },
                  child: const Text("Add Crypto"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (isLoadingTokens && tokens.isEmpty)
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
