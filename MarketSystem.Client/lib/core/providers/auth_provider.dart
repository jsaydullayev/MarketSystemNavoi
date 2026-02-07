import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService}) : _authService = authService;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);

      if (result != null) {
        _user = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login xato. Username yoki password noto\'g\'ri.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Xatolik yuz berdi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String fullName,
    required String username,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        fullName: fullName,
        username: username,
        password: password,
        role: role,
      );

      if (result != null) {
        _user = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Ro\'yxatdan o\'tish xato.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Xatolik yuz berdi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // Fetch user profile from backend
  Future<void> fetchUserProfile() async {
    try {
      final userService = UserService(authProvider: this);
      final profile = await userService.getMyProfile();
      _user = profile;
      notifyListeners();
    } catch (e) {
      // Silent fail - don't show error to user
      print('Error fetching profile: $e');
    }
  }

  // Check authentication status
  Future<void> checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth && _user == null) {
      // Agar token bor lekin user ma'lumoti yo'q bo'lsa
      // Token mavjud, demak user login bo'lgan
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
