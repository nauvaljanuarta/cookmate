import 'package:flutter/material.dart';
import 'dart:async';
import 'pages/mainscreen.dart';
import 'pages/homepage.dart';
import 'pages/profilepage.dart';
// import 'pages/search_page.dart';
// import 'pages/favorite_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorSchemeSeed: Color(0xFF365E32),
        useMaterial3: true,
      ),
      initialRoute: '/', // Halaman pertama yang dibuka
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        // '/search': (context) => const SearchPage(),
        // '/favorite': (context) => const FavoritePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A7D44), // Background hijau gelap
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.food_bank, size: 80, color: Color(0xFFF8F5E9)), // Ikon putih agar kontras
              SizedBox(height: 20),
              Text(
                "CookMate",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8F5E9), // Teks putih biar jelas
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
