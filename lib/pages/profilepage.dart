import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/profile.jpg'),
                ),
                SizedBox(height: 20),
                Text(
                  "Januarta",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF365E32),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "johndoe@example.com",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 16,
                    color: Color(0xFF5A5A5A),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: Colors.black26,
            indent: 30,
            endIndent: 30,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.settings, color: Color(0xFF365E32)),
                    title: Text(
                      "Settings",
                      style: TextStyle(fontFamily: "Montserrat"),
                    ),
                    onTap: () {
                      // Aksi untuk navigasi ke Settings
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      "Logout",
                      style: TextStyle(fontFamily: "Montserrat"),
                    ),
                    onTap: () {
                      // Aksi untuk logout
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
