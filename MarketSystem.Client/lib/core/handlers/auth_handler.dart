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

  /// Initialize auth handler
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save authentication token
  Future<bool> saveToken(String token) async {
    await init();
    return await _prefs!.setString(_tokenKey, token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    await init();
    return _prefs!.getString(_tokenKey);
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String refreshToken) async {
    await init();
    return await _prefs!.setString(_refreshTokenKey, refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    await init();
    return _prefs!.getString(_refreshTokenKey);
  }

  /// Save user ID
  Future<bool> saveUserId(int userId) async {
    await init();
    return await _prefs!.setInt(_userIdKey, userId);
  }

  /// Get user ID
  Future<int?> getUserId() async {
    await init();
    return _prefs!.getInt(_userIdKey);
  }

  /// Save user name
  Future<bool> saveUserName(String userName) async {
    await init();
    return await _prefs!.setString(_userNameKey, userName);
  }

  /// Get user name
  Future<String?> getUserName() async {
    await init();
    return _prefs!.getString(_userNameKey);
  }

  /// Save user role
  Future<bool> saveUserRole(String role) async {
    await init();
    return await _prefs!.setString(_userRoleKey, role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    await init();
    return _prefs!.getString(_userRoleKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all authentication data (logout)
  Future<bool> clearAuth() async {
    await init();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_userIdKey);
    await _prefs!.remove(_userNameKey);
    await _prefs!.remove(_userRoleKey);
    return true;
  }

  /// Clear specific key
  Future<bool> clearKey(String key) async {
    await init();
    return await _prefs!.remove(key);
  }

  /// Get all auth data as map
  Future<Map<String, dynamic>> getAuthData() async {
    await init();
    return {
      'token': await getToken(),
      'refreshToken': await getRefreshToken(),
      'userId': await getUserId(),
      'userName': await getUserName(),
      'userRole': await getUserRole(),
    };
  }
}
