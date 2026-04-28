import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ApiService {
  static const base = 'https://api.judisai.in/';
  final AuthService _auth;

  ApiService(this._auth);

  Future<Map<String, String>> _headers() async {
    final token = await _auth.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$base$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$base$path'), headers: headers);
    return jsonDecode(res.body);
  }
}
