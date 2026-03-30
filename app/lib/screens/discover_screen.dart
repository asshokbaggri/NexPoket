import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Theme based
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔍 Search
              TextField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Search dApps...",
                  hintStyle: const TextStyle(color: Colors.grey),

                  filled: true,
                  fillColor: Colors.grey.shade100,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Categories",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _CategoryChip("DeFi"),
                  _CategoryChip("NFT"),
                  _CategoryChip("Games"),
                  _CategoryChip("Tools"),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                "Popular dApps",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 15),

              // 🔥 dApps list
              Expanded(
                child: ListView(
                  children: const [
                    _DappTile("Uniswap", "Swap tokens easily"),
                    _DappTile("OpenSea", "NFT marketplace"),
                    _DappTile("PancakeSwap", "DeFi trading"),
                    _DappTile("Aave", "Lend & Borrow crypto"),
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

// 🔹 Category Chip (Modern)
class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),

      backgroundColor: Colors.grey.shade100,
      labelStyle: const TextStyle(color: Colors.black),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// 🔹 dApp Tile (Card UI)
class _DappTile extends StatelessWidget {
  final String name, desc;

  const _DappTile(this.name, this.desc);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
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

          const CircleAvatar(
            backgroundColor: Color(0xFF3375BB),
            child: Icon(Icons.language, color: Colors.white),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.black),
              ),
              Text(
                desc,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}