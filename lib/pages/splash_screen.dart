import 'package:cookmate2/pages/auth/login_page.dart';
import 'package:cookmate2/pages/home/home_page.dart';
import 'package:cookmate2/services/user_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:cookmate2/config/pocketbase_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    await _userService.restoreAuthToken();

    if (mounted) {
      if (PocketBaseClient.instance.authStore.isValid) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.activeOrange,
            CupertinoColors.systemYellow,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/splash.svg',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 24),
            const Text(
              'Cookmate',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: CupertinoColors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none, 
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your personal cooking assistant',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: CupertinoColors.white,
                fontSize: 16,
                decoration: TextDecoration.none, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}
