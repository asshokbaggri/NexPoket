import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
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
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NexPoket User",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        "View Profile",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Security",
                style: TextStyle(
                  color: Colors.white70,
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
                  color: Colors.white70,
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

// 🔹 Settings Tile
Widget _tile(IconData icon, String title) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C2E),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
      onTap: () {},
    ),
  );
}