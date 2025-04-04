import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  const SplashScreen({super.key, required this.toggleTheme});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A7D44),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.food_bank, size: 100, color: Color(0xFFF8F5E9)), // Ikon lebih besar
                SizedBox(height: 20),
                Text(
                  "CookMate",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 28, // Ukuran teks lebih besar
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF8F5E9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
