import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const baseUrl = 'https://gia-store-production.up.railway.app/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path) async {
    return http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
  }

  static Future<http.Response> post(String path, Map body) async {
    return http.post(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> put(String path, Map body) async {
    return http.put(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    return http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
  }

  static Future<http.Response> patch(String path) async {
    return http.patch(Uri.parse('$baseUrl$path'), headers: await _headers());
  }

  static Future<http.Response> patch2(String path, Map body) async {
    return http.patch(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> getBytes(String path) async {
    return http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
  }
}
