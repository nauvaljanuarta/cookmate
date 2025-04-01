import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.kitchen, size: 100, color: Color(0xFF365E32)),
            SizedBox(height: 20),
            Text(
              "Welcome to CookMate",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF365E32),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Discover new recipes & cook like a pro!",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5A5A5A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
