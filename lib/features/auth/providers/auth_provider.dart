import 'package:flutter/foundation.dart';
import '../../../core/models/user.dart';
import '../../../core/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _loadUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();

    _user = await _authService.loadUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;

      if (_user == null) {
        _errorMessage = 'Email atau password salah';
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    int? gradeLevel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        gradeLevel: gradeLevel,
      );

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void updateUserAbility(double theta) {
    if (_user != null) {
      _user = _user!.copyWith(abilityTheta: theta);
      _authService.updateUser(_user!);
      notifyListeners();
    }
  }

  void addXP(int xp) {
    if (_user != null) {
      final newXP = _user!.xp + xp;
      final newLevel = (newXP / 100).floor() + 1;

      _user = _user!.copyWith(
        xp: newXP,
        level: newLevel,
      );

      _authService.updateUser(_user!);
      notifyListeners();
    }
  }

  void updateStreak(int streak) {
    if (_user != null) {
      _user = _user!.copyWith(streak: streak);
      _authService.updateUser(_user!);
      notifyListeners();
    }
  }
}
