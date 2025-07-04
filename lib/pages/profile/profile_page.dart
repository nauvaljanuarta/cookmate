// lib/pages/profile/profile_page.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/user.dart';
import 'package:cookmate2/services/user_service.dart';
import 'package:cookmate2/pages/auth/login_page.dart';
import 'package:cookmate2/pages/profile/recipes_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  bool isEditing = false;
  bool isLoading = true;
  String? errorMessage;
  File? _imageFile; // Tambahkan state untuk menyimpan file gambar yang dipilih

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker(); // Tambahkan image picker

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      currentUser = _userService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          errorMessage = 'Silakan login untuk melihat profil';
          isLoading = false;
        });
        return;
      }

      _usernameController.text = currentUser!.username;
      _bioController.text = currentUser!.bio;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data pengguna: $e';
        isLoading = false;
      });
      print('ProfilePage: Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _toggleEdit() async {
    if (isEditing) {
      if (_usernameController.text.isEmpty) {
        _showAlert('Username tidak boleh kosong');
        return;
      }

      setState(() {
        isLoading = true;
      });

      final data = {
        'username': _usernameController.text,
        'bio': _bioController.text,
      };

      final (success, error) = await _userService.updateUser(
        data,
        profileImage: _imageFile,
      );

      setState(() {
        isLoading = false;
      });

      if (success) {
        setState(() {
          isEditing = false;
          _imageFile = null; // Reset file gambar setelah berhasil
        });
        _showAlert('Profil berhasil diperbarui');
        await _loadUserData(); // Muat ulang data untuk menampilkan gambar baru
      } else {
        _showAlert(error ?? 'Gagal memperbarui profil');
      }
    } else {
      setState(() {
        isEditing = true;
      });
    }
  }

  void _logout() async {
    _userService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isEditing && message.contains('berhasil') ? 'Sukses' : 'Error'),
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
    if (isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (errorMessage != null || currentUser == null) {
      // ... (UI untuk error state tidak berubah)
      return CupertinoPageScaffold(
        child: Center(child: Text(errorMessage ?? 'Data pengguna tidak tersedia')),
      );
    }

    final profileImageUrl = currentUser!.profileImage != null && currentUser!.profileImage!.isNotEmpty
        ? PocketBaseClient.instance.files
            .getUrl(
              PocketBaseClient.instance.authStore.model as RecordModel,
              currentUser!.profileImage!,
            )
            .toString()
        : null;
    
    // Tentukan gambar mana yang akan ditampilkan
    ImageProvider displayImage;
    if (_imageFile != null) {
      displayImage = FileImage(_imageFile!);
    } else if (profileImageUrl != null) {
      displayImage = NetworkImage(profileImageUrl);
    } else {
      displayImage = const NetworkImage('https://placehold.co/300?text=unknown&font=poppins');
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isLoading ? null : _toggleEdit,
          child: Text(
            isEditing ? 'Save' : 'Edit',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      // Modifikasi tampilan gambar profil
                      GestureDetector(
                        onTap: isEditing ? _pickImage : null,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: displayImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (isEditing)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.camera_fill,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      isEditing
                          ? CupertinoTextField(
                              controller: _usernameController,
                              textAlign: TextAlign.center,
                              style: AppTheme.subheadingStyle,
                              placeholder: 'Username',
                            )
                          : Text(
                              currentUser!.username,
                              style: AppTheme.subheadingStyle,
                            ),
                      const SizedBox(height: 8),
                      isEditing
                          ? CupertinoTextField(
                              controller: _bioController,
                              textAlign: TextAlign.center,
                              style: AppTheme.captionStyle,
                              placeholder: 'Tambah bio',
                              maxLines: 3,
                            )
                          : Text(
                              currentUser!.bio,
                              style: AppTheme.captionStyle,
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
                // ... (sisa UI tidak berubah)
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Resep', '0'),
                      _buildStatItem('Pengikut', '245'),
                      _buildStatItem('Mengikuti', '86'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Settings', style: AppTheme.subheadingStyle),
                const SizedBox(height: 12),
                _buildSettingsItem(icon: CupertinoIcons.book, title: 'My Recipes', onTap: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const RecipesPage()));
                }),
                _buildSettingsItem(icon: CupertinoIcons.bell, title: 'Notification', onTap: () {}),
                _buildSettingsItem(icon: CupertinoIcons.lock, title: 'Privacy', onTap: () {}),
                _buildSettingsItem(icon: CupertinoIcons.question_circle, title: 'Help & Support', onTap: () {}),
                _buildSettingsItem(icon: CupertinoIcons.arrow_right_square, title: 'Logout', onTap: _logout, showDivider: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.bodyStyle,
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: CupertinoColors.systemGrey5,
          ),
      ],
    );
  }
}