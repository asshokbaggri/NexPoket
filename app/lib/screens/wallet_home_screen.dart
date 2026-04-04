// app/lib/screens/wallet_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/storage_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'seed_phrase_screen.dart';
import 'import_wallet_screen.dart';

class WalletHomeScreen extends StatefulWidget {
  final String walletAddress;

  const WalletHomeScreen({super.key, required this.walletAddress});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {

  String walletName = "Wallet";
  String currentAddress = "";
  List<Map<String, dynamic>> wallets = [];

  @override
  void initState() {
    super.initState();
    currentAddress = widget.walletAddress;
    loadWallets();
  }

  Future<void> loadWallets() async {
    final data = await StorageService.getWallets();

    if (data.isEmpty) return;

    // 🔥 CLEAN NAMING SYSTEM
    for (int i = 0; i < data.length; i++) {
      data[i]["name"] = "Wallet ${i + 1}";
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

  void copyAddress() {
    Clipboard.setData(ClipboardData(text: currentAddress));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address Copied ✔")),
    );
  }

  // 🔥 FIXED (NO NAVIGATION)
  void switchWallet(String address) async {
    await StorageService.setSelectedWallet(address);

    setState(() {
      currentAddress = address;
    });

    loadWallets();

    Navigator.pop(context); // close bottom sheet
  }

  // 🔥 ADD WALLET POPUP
  void showAddWalletPopup() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.add_circle_outline),
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
                leading: const Icon(Icons.import_export),
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

  // 🔥 RENAME
  void renameWallet(String address, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Wallet"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              await StorageService.renameWallet(
                address,
                controller.text.trim(),
              );

              Navigator.pop(context);
              loadWallets();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // 🔥 WALLET LIST
  void showWalletList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              onLongPress: () =>
                  renameWallet(w["address"], w["name"]),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddWalletPopup,
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3375BB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Balance", style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text(
                      "0.00 ETH",
                      style: TextStyle(
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
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: copyAddress,
                      child: const Icon(
                        Icons.copy,
                        color: Color(0xFF3375BB),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  _actionButton(
                    context,
                    Icons.send,
                    "Send",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendScreen(
                            walletAddress: currentAddress,
                          ),
                        ),
                      );
                    },
                  ),

                  _actionButton(
                    context,
                    Icons.download,
                    "Receive",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiveScreen(
                            walletAddress: currentAddress,
                          ),
                        ),
                      );
                    },
                  ),

                  _actionButton(
                    context,
                    Icons.add,
                    "Buy",
                    () {},
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Your Assets",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: Center(
                  child: Text(
                    "No assets yet",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 ACTION BUTTON
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