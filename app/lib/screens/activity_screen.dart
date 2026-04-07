// app/lib/screens/activity_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ActivityScreen extends StatefulWidget {
  final String address;
  final String network;

  const ActivityScreen({
    super.key,
    required this.address,
    required this.network,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {

  List txs = [];
  bool isLoading = true;

  final String apiKey = "S97UPFBS6EJRSNUHQU1PD25KNT89UJKX6C";

  String getApiUrl() {
    switch (widget.network) {
      case "BSC":
        return "https://api.bscscan.com/api";
      case "Polygon":
        return "https://api.polygonscan.com/api";
      default:
        return "https://api.etherscan.io/api";
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTxs();
  }

  Future<void> fetchTxs() async {
    try {
      final url = Uri.parse(
        "${getApiUrl()}?module=account&action=txlist"
        "&address=${widget.address}"
        "&startblock=0&endblock=99999999"
        "&sort=desc&apikey=$apiKey",
      );

      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data["status"] == "1") {
        setState(() {
          txs = data["result"];
          isLoading = false;
        });
      } else {
        setState(() {
          txs = [];
          isLoading = false;
        });
      }

    } catch (e) {
      setState(() {
        txs = [];
        isLoading = false;
      });
    }
  }

  String formatTime(String timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(
        int.parse(timestamp) * 1000);

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} days ago";
  }

  String getSymbol() {
    switch (widget.network) {
      case "BSC":
        return "BNB";
      case "Polygon":
        return "POL";
      default:
        return "ETH";
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (txs.isEmpty)
                const Expanded(
                  child: Center(child: Text("No Transactions Found")),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: txs.length,
                    itemBuilder: (context, index) {

                      final tx = txs[index];

                      final isSend =
                          tx["from"].toLowerCase() ==
                          widget.address.toLowerCase();

                      final value = double.parse(tx["value"]) /
                          1000000000000000000;

                      return _TxTile(
                        type: isSend ? "Send" : "Receive",
                        amount:
                            "${isSend ? "-" : "+"}${value.toStringAsFixed(5)} ${getSymbol()}",
                        date: formatTime(tx["timeStamp"]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔥 TILE
class _TxTile extends StatelessWidget {
  final String type, amount, date;

  const _TxTile({
    required this.type,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isSend = type == "Send";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: isSend
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            child: Icon(
              isSend ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSend ? Colors.red : Colors.green,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          Text(
            amount,
            style: TextStyle(
              color: isSend ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
