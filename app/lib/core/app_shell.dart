import 'package:flutter/material.dart';
import '../screens/wallet_home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WalletHomeScreen(),
    DiscoverScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    "Wallet",
    "Discover",
    "Activity",
    "Settings"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ LIGHT MODE (theme based)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Discover",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}