import 'package:flutter/material.dart';
import '../core/storage_service.dart';
import '../screens/wallet_home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  final String walletAddress;

  const AppShell({super.key, required this.walletAddress});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  String selectedNetwork = "BSC";

  List<Widget> _screens = [];

  final List<String> _titles = [
    "",
    "Discover",
    "Activity",
    "Settings"
  ];

  @override
  void initState() {
    super.initState();
    initNetwork();
  }

  Future<void> initNetwork() async {
    final net = await StorageService.getSelectedNetwork();

    setState(() {
      selectedNetwork = net;

      _screens = [
        WalletHomeScreen(
          walletAddress: widget.walletAddress,
          network: selectedNetwork,
        ),
        const DiscoverScreen(),
        const ActivityScreen(),
        const SettingsScreen(),
      ];
    });
  }

  void changeNetwork(String network) async {
    await StorageService.setSelectedNetwork(network);

    setState(() {
      selectedNetwork = network;

      _screens[0] = WalletHomeScreen(
        walletAddress: widget.walletAddress,
        network: selectedNetwork,
      );
    });
  }

  String getNetworkLabel(String net) {
    switch (net) {
      case "BSC":
        return "BNB";
      case "Ethereum":
        return "ETH";
      case "Polygon":
        return "POL";
      default:
        return net;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: _currentIndex == 0
            ? Row(
                children: [

                  // 🔥 LEFT SIDE EMPTY SPACE (balance alignment)
                  const Spacer(),

                  // 🔥 NETWORK DROPDOWN RIGHT SIDE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    child: DropdownButton<String>(
                      value: selectedNetwork,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down),

                      items: const [
                        DropdownMenuItem(
                          value: "BSC",
                          child: Text("BNB"),
                        ),
                        DropdownMenuItem(
                          value: "Ethereum",
                          child: Text("ETH"),
                        ),
                        DropdownMenuItem(
                          value: "Polygon",
                          child: Text("POL"),
                        ),
                      ],

                      onChanged: (val) {
                        if (val != null) changeNetwork(val);
                      },
                    ),
                  ),
                ],
              )
            : Text(_titles[_currentIndex]),
      ),

      body: _screens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore), label: "Discover"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}