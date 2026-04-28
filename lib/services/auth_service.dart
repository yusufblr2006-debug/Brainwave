import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock auth service — no Firebase dependency required.
/// Simulates login/register with email/password, stores state in SharedPreferences.
class AuthService {
  bool _isLoggedIn = false;
  String? _email;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;
  String? get email => _email;
  String? get displayName => _displayName;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('logged_in') ?? false;
    _email = prefs.getString('email');
    _displayName = prefs.getString('display_name');
  }

  Future<void> signIn(String email, String password) async {
    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 800));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    _isLoggedIn = true;
    _email = email;
    _displayName = email.split('@').first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    await prefs.setString('email', email);
    await prefs.setString('display_name', _displayName!);
  }

  Future<void> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    _isLoggedIn = true;
    _email = email;
    _displayName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    await prefs.setString('email', email);
    await prefs.setString('display_name', name);
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    _email = null;
    _displayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> get token async => _isLoggedIn ? 'mock-token-${_email ?? "anon"}' : null;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
