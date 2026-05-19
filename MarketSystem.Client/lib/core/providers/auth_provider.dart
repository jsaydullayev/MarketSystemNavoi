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
  // Surfaces the structured reason a login attempt failed (market blocked,
  // invalid creds, network down, etc.) so the screen can render the right UI.
  // Login screen reads this AFTER `login()` returns false.
  LoginOutcome? _loginOutcome;
  String? _loginBlockReason;
  DateTime? _loginBlockedAt;
  LoginOutcome? get loginOutcome => _loginOutcome;
  String? get loginBlockReason => _loginBlockReason;
  DateTime? get loginBlockedAt => _loginBlockedAt;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorCode = null;
    _loginOutcome = null;
    _loginBlockReason = null;
    _loginBlockedAt = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      _loginOutcome = result.outcome;

      if (result.outcome == LoginOutcome.success && result.user != null) {
        _user = result.user;
        if (_user?['language'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_locale', _user!['language']);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Non-success branches — preserve structured info for the UI.
      switch (result.outcome) {
        case LoginOutcome.marketBlocked:
          _loginBlockReason = result.blockReason;
          _loginBlockedAt = result.blockedAt;
          _errorCode = 'market_blocked';
          break;
        case LoginOutcome.invalidCredentials:
          _errorCode = 'login_failed';
          break;
        case LoginOutcome.rateLimited:
          _errorCode = 'rate_limited';
          break;
        case LoginOutcome.networkError:
          _errorCode = 'network_error';
          break;
        case LoginOutcome.unknown:
        case LoginOutcome.success:
          _errorCode = 'login_failed';
          break;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('AuthProvider.login error: $e\n$st');
      _errorCode = 'network_error';
      _loginOutcome = LoginOutcome.networkError;
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
    } catch (e, st) {
      debugPrint('AuthProvider.register error: $e\n$st');
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

  int _profileImageVersion = 0;
  int get profileImageVersion => _profileImageVersion;

  Future<void> fetchUserProfile() async {
    try {
      final userService = UserService(authProvider: this);
      final profile = await userService.getMyProfile();

      if (_user?['profileImage'] != profile['profileImage']) {
        _profileImageVersion++;
      }

      _user = profile;
      notifyListeners();
    } catch (e, st) {
      debugPrint('AuthProvider.fetchUserProfile error: $e\n$st');
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
    } catch (e, st) {
      debugPrint('AuthProvider.updateToken error: $e\n$st');
      _errorCode = 'token_update_failed';
      notifyListeners();
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

  void setUserFromStorage(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
  }
}
