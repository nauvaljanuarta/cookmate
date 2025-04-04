import 'package:flutter/material.dart';
import 'pages/mainscreen.dart';
import 'pages/homepage.dart';
import 'pages/profilepage.dart';
import 'theme.dart';
import 'splashscreen.dart'; // ✅ Import splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(toggleTheme: _toggleTheme),
        '/main': (context) => MainScreen(toggleTheme: _toggleTheme),
        '/home': (context) => const HomePage(),
        '/profile': (context) => ProfilePage(toggleTheme: _toggleTheme),
      },
    );
  }
}
