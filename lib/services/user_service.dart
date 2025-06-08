import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/user.dart';

class UserService {
  Future<(RecordModel?, String?)> registerUser({
    required String email,
    required String password,
    required String passwordConfirm,
    required String username,
    String? bio,
    File? profileImage,
  }) async {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return (null, 'Email tidak valid');
    }
    if (password != passwordConfirm) {
      return (null, 'Password dan konfirmasi tidak cocok');
    }
    if (password.length < 8) {
      return (null, 'Password harus minimal 8 karakter');
    }

    final body = <String, dynamic>{
      "email": email,
      "emailVisibility": true,
      "username": username,
      "password": password,
      "passwordConfirm": passwordConfirm,
      "bio": bio ?? '',
    };

    try {
      final record = await PocketBaseClient.instance.collection('users').create(body: body);
      if (profileImage != null) {
        final updatedRecord = await PocketBaseClient.instance.collection('users').update(
          record.id,
          files: [
            await http.MultipartFile.fromPath(
              'profileImage',
              profileImage.path,
              filename: 'profile_${record.id}.jpg',
            ),
          ],
        );
      }

      try {
        await PocketBaseClient.instance.collection('users').requestVerification(email);
        print('Permintaan verifikasi email terkirim untuk: $email');
      } catch (e) {
        print('Gagal mengirim verifikasi email: $e');
      }
      return (record, null);
    } catch (e) {
      print('Error saat registrasi: $e');
      String errorMessage;
      if (e is ClientException) {
        final response = e.response;
        errorMessage = response['message'] ??
            response['data']?['email']?['message'] ??
            response['data']?['username']?['message'] ??
            'Gagal register: ${e.toString()}';
        print('Detail error ClientException: $response');
      } else {
        errorMessage = 'Gagal register: ${e.toString()}';
      }
      return (null, errorMessage);
    }
  }

  Future<(bool, String?)> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final authData = await PocketBaseClient.instance.collection('users').authWithPassword(email, password);

      PocketBaseClient.instance.authStore.save(authData.token, authData.record);
      await _saveAuthToken(authData.token, authData.record);

      return (authData.token.isNotEmpty, null);
    } catch (e) {
      print('Error saat login: $e');
      String errorMessage;
      if (e is ClientException) {
        errorMessage = e.response['message'] ?? 'Gagal login: ${e.toString()}';
      } else {
        errorMessage = 'Gagal login: ${e.toString()}';
      }
      return (false, errorMessage);
    }
  }

  User? getCurrentUser() {
    final record = PocketBaseClient.instance.authStore.model;
    print('getCurrentUser: Auth store token: ${PocketBaseClient.instance.authStore.token}');
    print('getCurrentUser: Auth store model: ${record?.toJson()}');
    if (record == null) {
      print('No current user found');
      return null;
    }
    try {
      final user = User.fromRecord(record);
      print('Current user: ${user.toJson()}');
      return user;
    } catch (e) {
      print('Error converting RecordModel to User: $e');
      return null;
    }
  }

  void logout() {
    print('Logging out, clearing auth store');
    PocketBaseClient.instance.authStore.clear();
    _clearAuthToken();
  }

  Future<(bool, String?)> updateUser(Map<String, dynamic> data) async {
    final user = getCurrentUser();
    if (user == null) {
      print('Update gagal: Tidak ada pengguna yang login');
      return (false, 'Tidak ada pengguna yang login');
    }
    try {
      print('Mengirim request update user: $data');
      await PocketBaseClient.instance.collection('users').update(user.id, body: data);
      print('Update user berhasil');
      return (true, null);
    } catch (e) {
      print('Error saat update user: $e');
      String errorMessage;
      if (e is ClientException) {
        errorMessage = e.response['message'] ?? 'Gagal update user: ${e.toString()}';
      } else {
        errorMessage = 'Gagal update user: ${e.toString()}';
      }
      return (false, errorMessage);
    }
  }

  Future<String> testConnection() async {
    try {
      await PocketBaseClient.instance.collection('users').getList(perPage: 1);
      print('Koneksi berhasil');
      return 'Koneksi berhasil!';
    } catch (e) {
      print('Koneksi gagal: $e');
      return 'Koneksi gagal: $e';
    }
  }

  Future<void> _saveAuthToken(String token, RecordModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_model', jsonEncode(model.toJson()));
    print('Saved auth token and model to SharedPreferences');
  }

  Future<void> restoreAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final modelJson = prefs.getString('auth_model');
    if (token != null && modelJson != null) {
      try {
        final model = RecordModel.fromJson(jsonDecode(modelJson));
        PocketBaseClient.instance.authStore.save(token, model);
        print('Restored auth token and model from SharedPreferences');
      } catch (e) {
        print('Error restoring auth token: $e');
      }
    }
  }

  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_model');
    print('Cleared auth token and model from SharedPreferences');
  }
}