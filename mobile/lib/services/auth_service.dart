import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, String>?> login(String username, String password) async {
    final res = await ApiService.post('/auth/login', {'username': username, 'password': password});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('username', data['username']);
      await prefs.setString('role', data['role'] ?? 'CUSTOMER');
      await prefs.setString('userId', data['userId'] ?? '');
      return {'role': data['role'] ?? 'CUSTOMER', 'userId': data['userId'] ?? ''};
    }
    return null;
  }

  static Future<bool> register(String username, String password, String fullName, String phone) async {
    final res = await ApiService.post('/auth/register', {
      'username': username, 'password': password,
      'fullName': fullName, 'phone': phone,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? 'CUSTOMER';
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'User';
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  static Future<void> updateUsername(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }
}
