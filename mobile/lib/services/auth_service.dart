import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    final res = await ApiService.post('/auth/login', {'username': username, 'password': password});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('username', data['username']);
      return true;
    }
    return false;
  }

  static Future<bool> register(String username, String password) async {
    final res = await ApiService.post('/auth/register', {'username': username, 'password': password});
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Admin';
  }

  static Future<void> updateUsername(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }
}
