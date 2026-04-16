// app/lib/screens/token_detail_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../core/wallet_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class TokenDetailScreen extends StatefulWidget {
  final String symbol;
  final double balance;
  final double price;
  final double change;
  final String walletAddress;

  final String network;
  final String contract;
  final bool isNative;

  const TokenDetailScreen({
    super.key,
    required this.symbol,
    required this.balance,
    required this.price,
    required this.change,
    required this.walletAddress,
    required this.network,
    required this.contract,
    required this.isNative,
  });

  @override
  State<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends State<TokenDetailScreen> {

  List<FlSpot> chartData = [];
  bool isLoadingChart = true;

  double livePrice = 0;
  double liveChange = 0;

  String selectedTime = "1D";

  Timer? priceTimer;

  @override
  void initState() {
    super.initState();

    livePrice = widget.price;
    liveChange = widget.change;

    loadChart();
    startLivePrice();
  }

  @override
  void dispose() {
    priceTimer?.cancel();
    super.dispose();
  }

  // ============================
  // 🔥 LIVE PRICE SYNC
  // ============================

  void startLivePrice() {
    priceTimer = Timer.periodic(const Duration(seconds: 5), (_) async {

      final prices = await WalletService.getLivePricesAdvanced(
        [
          {
            "symbol": widget.symbol,
            "contract": widget.contract,
            "isNative": widget.isNative,
          }
        ],
        widget.network,
      );

      if (!mounted) return;

      setState(() {
        livePrice = prices[widget.symbol]?["price"] ?? livePrice;
        liveChange = prices[widget.symbol]?["change"] ?? liveChange;
      });
    });
  }

  // ============================
  // 🔥 TIMEFRAME → DAYS MAP
  // ============================

  int getDays() {
    switch (selectedTime) {
      case "LIVE":
      case "1m":
      case "15m":
      case "1H":
        return 1;
      case "1D":
        return 1;
      case "1W":
        return 7;
      case "1M":
        return 30;
      default:
        return 1;
    }
  }

  // ============================
  // 🔥 CHART DATA
  // ============================

  Future<void> loadChart() async {

    setState(() => isLoadingChart = true);

    try {
      final id = await WalletService.resolveCoinGeckoId(widget.symbol);
      if (id == null) return;

      final days = getDays();

      final url = Uri.parse(
        "https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=usd&days=$days",
      );

      final res = await http.get(url);
      final data = jsonDecode(res.body);

      final prices = data["prices"] as List;

      List<FlSpot> spots = [];

      for (int i = 0; i < prices.length; i++) {
        final p = prices[i];
        spots.add(FlSpot(i.toDouble(), (p[1] as num).toDouble()));
      }

      if (!mounted) return;

      setState(() {
        chartData = spots;
        isLoadingChart = false;
      });

    } catch (e) {
      setState(() => isLoadingChart = false);
    }
  }

  // ============================
  // UI
  // ============================

  @override
  Widget build(BuildContext context) {

    final usdValue = widget.balance * livePrice;

    final iconPath = WalletService.resolveLocalIcon(widget.symbol);

    final fallbackUrl = WalletService.resolveFallbackIcon(
      network: widget.network,
      contract: widget.contract,
      isNative: widget.isNative,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return Image.network(
                      fallbackUrl,
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.currency_bitcoin, size: 20),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),
            Text(widget.symbol),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔥 PRICE
            Text(
              "\$${livePrice.toStringAsFixed(4)}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              "${liveChange >= 0 ? "+" : ""}${liveChange.toStringAsFixed(2)}%",
              style: TextStyle(
                color: liveChange >= 0 ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 CHART
            isLoadingChart
                ? const CircularProgressIndicator()
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                            color: const Color(0xFF00AEEF),
                            barWidth: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

            const SizedBox(height: 15),

            // 🔥 TRUST WALLET STYLE TIMEFRAME
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeBtn("LIVE"),
                _timeBtn("1m"),
                _timeBtn("15m"),
                _timeBtn("1H"),
                _timeBtn("1D"),
                _timeBtn("1W"),
                _timeBtn("1M"),
              ],
            ),

            const SizedBox(height: 25),

            // 🔥 HOLDINGS
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Holdings"),
                      Text(widget.balance.toStringAsFixed(6)),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Value"),
                      Text("\$${usdValue.toStringAsFixed(2)}"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _btn(Icons.send, "Send", () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SendScreen(walletAddress: widget.walletAddress),
                  ));
                }),
                _btn(Icons.download, "Receive", () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ReceiveScreen(walletAddress: widget.walletAddress),
                  ));
                }),
                _btn(Icons.swap_horiz, "Swap", () {}),
                _btn(Icons.shopping_cart, "Buy", () {}),
              ],
            ),

            const SizedBox(height: 30),

            const Text("Transaction History",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            const Text("Coming Soon"),
          ],
        ),
      ),
    );
  }

  // ============================
  // 🔥 TIME BUTTON
  // ============================

  Widget _timeBtn(String label) {
    final isActive = selectedTime == label;

    return GestureDetector(
      onTap: () {
        setState(() => selectedTime = label);
        loadChart();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3375BB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF3375BB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF3375BB)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}