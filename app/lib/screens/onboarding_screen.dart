import 'package:flutter/material.dart';
import 'wallet_setup_screen.dart';

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
      _goToWalletSetup();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
          children: [

            // 🔹 Skip (FIXED)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToWalletSetup,
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Color(0xFF3375BB), // ✅ better visibility
                    fontWeight: FontWeight.w500,
                  ),
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
                          color: Color(0xFF3375BB),
                        ),

                        const SizedBox(height: 40),

                        Text(
                          _pages[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black, // ✅ FIX
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _pages[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600, // ✅ better contrast
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔹 Dots (FIXED)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: _currentIndex == index ? 14 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? const Color(0xFF3375BB)
                        : (isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade400), // ✅ FIX
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Button (FIXED)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3375BB),
                  foregroundColor: Colors.white, // ✅ FIX (important)
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