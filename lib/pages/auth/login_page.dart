import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/services/user_service.dart';
import 'package:cookmate2/pages/auth/register_page.dart';
import 'package:cookmate2/pages/home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAlert('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final (
      success,
      error
    ) = await _userService.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        print('LoginPage: Login successful, navigating to HomeScreen');
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        print('LoginPage: Login failed: $error');
        _showAlert(error ?? 'Failed to login');
      }
    }
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/images/splash.svg',
                          width: 70,
                          height: 70,
                          color: CupertinoColors.systemOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cookmate',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your personal cooking assistant',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Login form
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _emailController,
                      placeholder: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.mail,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Password',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Enter your password',
                      obscureText: _obscurePassword,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.lock,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Icon(
                            _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                _rememberMe ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                                color: _rememberMe ? AppTheme.primaryColor : CupertinoColors.systemGrey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Column(
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSocialButton(
                              icon: CupertinoIcons.globe,
                              label: 'Google',
                              onTap: () {},
                            ),
                            _buildSocialButton(
                              icon: CupertinoIcons.device_phone_portrait,
                              label: 'Apple',
                              onTap: () {},
                            ),
                            _buildSocialButton(
                              icon: CupertinoIcons.person_crop_circle,
                              label: 'Facebook',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
