import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/pages/home/home_screen.dart';
import 'package:cookmate2/pages/splash_screen.dart';

void main() {
  runApp(const CookmateApp());
}

class CookmateApp extends StatelessWidget {
  const CookmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Cookmate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cupertinoTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

