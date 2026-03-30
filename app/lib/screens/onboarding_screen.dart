import 'package:flutter/material.dart';
import 'wallet_setup_screen.dart'; // ✅ FIXED IMPORT

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Secure Your Crypto",
      "desc": "Your funds are fully under your control and protected."
    },
    {
      "title": "Send & Receive Easily",
      "desc": "Transfer crypto anywhere in seconds."
    },
    {
      "title": "Explore Web3",
      "desc": "Access dApps, NFTs and more with ease."
    },
  ];

  void _goToWalletSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WalletSetupScreen()),
    );
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _goToWalletSetup(); // ✅ FIXED FLOW
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ MEMORY FIX
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [

            // 🔹 Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToWalletSetup, // ✅ FIXED
                child: const Text(
                  "Skip",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const Icon(
                          Icons.account_balance_wallet,
                          size: 100,
                          color: Colors.deepPurple,
                        ),

                        const SizedBox(height: 40),

                        Text(
                          _pages[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _pages[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔹 Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.all(4),
                  width: _currentIndex == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.deepPurple
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _currentIndex == _pages.length - 1
                      ? "Get Started"
                      : "Next",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}