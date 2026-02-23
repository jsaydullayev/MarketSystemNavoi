import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/http_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService}) : _authService = authService;

  bool _isLoading = false;
  String? _errorCode;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;
  HttpService get httpService => _authService.httpService;

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);

      if (result != null) {
        _user = result;
        // Save language preference from server
        if (_user?['language'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_locale', _user!['language']);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorCode = 'login_failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorCode = 'network_error';
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
    String? marketName,
    String? language,
  }) async {
    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        fullName: fullName,
        username: username,
        password: password,
        role: role,
        marketName: marketName,
        language: language,
      );

      if (result != null) {
        _user = result;
        // Save language preference
        if (_user?['language'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_locale', _user!['language']);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorCode = 'register_failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorCode = 'network_error';
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

  // ✅ NEW: Update access token (e.g., after market registration)
  Future<void> updateToken(String newAccessToken) async {
    try {
      // Refresh token yangilanmaydi, faqat access token
      await _authService.updateAccessToken(newAccessToken);

      // User ma'lumotlarini yangilash
      await fetchUserProfile();

      notifyListeners();
    } catch (e) {
      print('Error updating token: $e');
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
    _errorCode = null;
    notifyListeners();
  }
}
