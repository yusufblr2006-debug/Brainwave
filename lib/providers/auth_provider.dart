import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Tracks if user is currently logged in
final isLoggedInProvider = StateProvider<bool>((ref) => false);

/// Current user display name
final userNameProvider = StateProvider<String>((ref) => 'Arjun');

/// Current user email
final userEmailProvider = StateProvider<String>((ref) => 'arjun@judisai.in');

/// User role: 'citizen' or 'lawyer'
final userRoleProvider = StateProvider<String>((ref) => 'citizen');

/// Auth service singleton
final authProvider = Provider<AuthService>((ref) => AuthService());
