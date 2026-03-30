import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Theme based
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [

              // 👤 Profile
              Row(
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF3375BB),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NexPoket User",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "View Profile",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Security",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              _tile(Icons.lock, "Change Password"),
              _tile(Icons.security, "Backup Wallet"),
              _tile(Icons.fingerprint, "Biometric Lock"),

              const SizedBox(height: 25),

              const Text(
                "General",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              _tile(Icons.language, "Language"),
              _tile(Icons.dark_mode, "Dark Mode"),
              _tile(Icons.info, "About App"),

              const SizedBox(height: 30),

              // 🚪 Logout
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out (demo)")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Settings Tile (Card Style)
Widget _tile(IconData icon, String title) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),

      // 🔥 soft shadow
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF3375BB)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {},
    ),
  );
}