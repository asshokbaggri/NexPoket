import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Theme based background
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
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView(
                  children: const [

                    _TxTile(
                      type: "Send",
                      amount: "-0.05 BTC",
                      date: "Today",
                    ),

                    _TxTile(
                      type: "Receive",
                      amount: "+0.10 ETH",
                      date: "Yesterday",
                    ),

                    _TxTile(
                      type: "Send",
                      amount: "-1 BNB",
                      date: "2 days ago",
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Transaction Tile (Modern Card)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        // 🔥 Soft shadow
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
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
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