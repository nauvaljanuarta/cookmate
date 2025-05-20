import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseClient {
  static final PocketBase pb = PocketBase('http://10.0.2.2:8090');
  static PocketBase get instance => pb;

  // Save auth token to SharedPreferences
  static Future<void> saveAuthToken(String token, RecordModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_model', model.toJson().toString());
    print('Saved auth token and model to SharedPreferences');
  }

  // Restore auth token from SharedPreferences
  static Future<void> restoreAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final modelJson = prefs.getString('auth_model');
    if (token != null && modelJson != null) {
      final model = RecordModel.fromJson(jsonDecode(modelJson));
      pb.authStore.save(token, model);
      print('Restored auth token and model from SharedPreferences');
    }
  }
}