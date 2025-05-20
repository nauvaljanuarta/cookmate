import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/pages/auth/login_page.dart';
import 'package:cookmate2/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showAlert('Failed to pick image: $e');
    }
  }

  void _register() async {
    // Validasi input lokal
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showAlert('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showAlert('Passwords do not match');
      return;
    }

    if (!_agreeToTerms) {
      _showAlert('Please agree to the Terms and Conditions');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Panggil UserService untuk registrasi
    final userService = UserService();
    final (record, error) = await userService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      username: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      profileImage: _profileImage,
    );

    setState(() {
      _isLoading = false;
    });

    
    if (record != null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } else {
      _showAlert(error ?? 'Registration failed. Please check your input and try again.');
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Create Account'),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Profile image picker
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                              width: 1,
                            ),
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? const Center(
                                  child: Icon(
                                    CupertinoIcons.camera,
                                    size: 40,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add Profile Picture',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form registrasi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Enter your full name',
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.person,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                      'Bio',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _bioController,
                      placeholder: 'Tell us about yourself',
                      padding: const EdgeInsets.all(16),
                      maxLines: 3,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          CupertinoIcons.pencil,
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
                      placeholder: 'Create a password',
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
                            _obscurePassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _confirmPasswordController,
                      placeholder: 'Confirm your password',
                      obscureText: _obscureConfirmPassword,
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
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          child: Icon(
                            _obscureConfirmPassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreeToTerms = !_agreeToTerms;
                        });
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _agreeToTerms
                                ? CupertinoIcons.checkmark_square_fill
                                : CupertinoIcons.square,
                            color: _agreeToTerms
                                ? AppTheme.primaryColor
                                : CupertinoColors.systemGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'By creating an account, you agree to our Terms of Service and Privacy Policy',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text(
                                'Create Account',
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              CupertinoPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
}