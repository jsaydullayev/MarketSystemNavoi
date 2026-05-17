/// Authentication Handler
/// Manages authentication tokens and user session
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Auth Handler - Manages authentication state
class AuthHandler {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Initialize auth handler
  Future<void> init() async {
    await _getPrefs();
  }

  /// Save authentication token
  Future<bool> saveToken(String token) async {
    final prefs = await _getPrefs();
    return prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_tokenKey);
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String refreshToken) async {
    final prefs = await _getPrefs();
    return prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save user ID
  Future<bool> saveUserId(int userId) async {
    final prefs = await _getPrefs();
    return prefs.setInt(_userIdKey, userId);
  }

  /// Get user ID
  Future<int?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_userIdKey);
  }

  /// Save user name
  Future<bool> saveUserName(String userName) async {
    final prefs = await _getPrefs();
    return prefs.setString(_userNameKey, userName);
  }

  /// Get user name
  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userNameKey);
  }

  /// Save user role
  Future<bool> saveUserRole(String role) async {
    final prefs = await _getPrefs();
    return prefs.setString(_userRoleKey, role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userRoleKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all authentication data (logout)
  Future<bool> clearAuth() async {
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    return true;
  }

  /// Clear specific key
  Future<bool> clearKey(String key) async {
    final prefs = await _getPrefs();
    return prefs.remove(key);
  }

  /// Get all auth data as map
  Future<Map<String, dynamic>> getAuthData() async {
    return {
      'token': await getToken(),
      'refreshToken': await getRefreshToken(),
      'userId': await getUserId(),
      'userName': await getUserName(),
      'userRole': await getUserRole(),
    };
  }
}
