// app/lib/core/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/storage_service.dart';
import '../core/wallet_service.dart';
import '../screens/wallet_home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  final String walletAddress;
  final String network;

  const AppShell({
    super.key,
    required this.walletAddress,
    required this.network,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late String selectedNetwork;

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

    selectedNetwork = widget.network;

    _buildScreens();
  }

  // 🔥 BUILD SCREENS FIX (ActivityScreen FIXED)
  void _buildScreens() {
    _screens = [
      WalletHomeScreen(
        walletAddress: widget.walletAddress,
        network: selectedNetwork,
      ),
      const DiscoverScreen(),
      ActivityScreen(
        address: widget.walletAddress,
        network: selectedNetwork,
      ),
      const SettingsScreen(),
    ];
  }

  void changeNetwork(String network) async {
    await StorageService.setSelectedNetwork(network);

    setState(() {
      selectedNetwork = network;

      _buildScreens(); // 🔥 rebuild all screens properly
    });
  }

  String getSymbol(String net) {
    return WalletService.getSymbol(net);
  }

  String getIcon(String net) {
    return WalletService.resolveLocalIcon(getSymbol(net));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🔥 TOP NETWORK SELECTOR WITH ICON
      appBar: AppBar(
        title: _currentIndex == 0
            ? Row(
                children: [
                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    child: DropdownButton<String>(
                      value: selectedNetwork,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down),

                      items: ["BSC", "Ethereum", "Polygon"].map((net) {

                        final iconPath = getIcon(net);

                        return DropdownMenuItem(
                          value: net,
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                iconPath,
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.currency_bitcoin),
                              ),
                              const SizedBox(width: 8),
                              Text(getSymbol(net)),
                            ],
                          ),
                        );
                      }).toList(),

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

      // 🔥 BOTTOM NAV WITH BETTER ICONS
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),

        selectedItemColor: const Color(0xFF3375BB),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Discover",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}