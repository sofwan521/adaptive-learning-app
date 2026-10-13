import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  static const String _keyUser = 'current_user';
  static const String _keyToken = 'auth_token';

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Login dengan email dan password
  Future<User?> login(String email, String password) async {
    // Simulasi login (dalam production, panggil API)
    await Future.delayed(const Duration(seconds: 1));

    // Hash password (dipakai saat integrasi API nanti)
    _hashPassword(password);

    // Mock user data - dalam production, ambil dari API
    if (email == 'student@test.com' && password == 'password') {
      final user = User(
        id: '1',
        name: 'Dika Muhammad',
        email: email,
        role: 'student',
        gradeLevel: 10,
        abilityTheta: 0.0,
        xp: 0,
        level: 1,
        streak: 0,
        createdAt: DateTime.now(),
      );

      await _saveUser(user);
      _currentUser = user;
      return user;
    }

    if (email == 'teacher@test.com' && password == 'password') {
      final user = User(
        id: '2',
        name: 'Guru Matematika',
        email: email,
        role: 'teacher',
        xp: 0,
        level: 1,
        streak: 0,
        createdAt: DateTime.now(),
      );

      await _saveUser(user);
      _currentUser = user;
      return user;
    }

    return null;
  }

  /// Register user baru
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    int? gradeLevel,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
      gradeLevel: gradeLevel,
      abilityTheta: 0.0,
      xp: 0,
      level: 1,
      streak: 0,
      createdAt: DateTime.now(),
    );

    await _saveUser(user);
    _currentUser = user;
    return user;
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
    _currentUser = null;
  }

  /// Load user dari local storage
  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);

    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        _currentUser = User.fromJson(userData);
        return _currentUser;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Update user data
  Future<void> updateUser(User user) async {
    _currentUser = user;
    await _saveUser(user);
  }

  /// Simpan user ke local storage
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Hash password menggunakan SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
