import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'http_service.dart';

class AuthService {
  final HttpService _httpService;

  AuthService({required HttpService httpService}) : _httpService = httpService;

  // Login
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _httpService.post(
        ApiConstants.login,
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _httpService.saveTokens(data['accessToken'], data['refreshToken']);
        return data;
      }
      return null;
    } catch (e, st) {
      debugPrint('AuthService.login error: $e\n$st');
      return null;
    }
  }

  // Register
  Future<Map<String, dynamic>?> register({
    required String fullName,
    required String username,
    required String password,
    required String role,
    String? marketName,
    String? language,
  }) async {
    try {
      final response = await _httpService.post(
        ApiConstants.register,
        body: {
          'fullName': fullName,
          'username': username,
          'password': password,
          'role': role,
          if (marketName != null) 'marketName': marketName,
          if (language != null) 'language': language,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _httpService.saveTokens(data['accessToken'], data['refreshToken']);
        return data;
      }
      return null;
    } catch (e, st) {
      debugPrint('AuthService.register error: $e\n$st');
      return null;
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final refreshToken = await _httpService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _httpService.post(
        ApiConstants.logout,
        body: {'refreshToken': refreshToken},
      );

      await _httpService.clearTokens();
      return response.statusCode == 200;
    } catch (e, st) {
      debugPrint('AuthService.logout error: $e\n$st');
      await _httpService.clearTokens();
      return true;
    }
  }

  // Token borligini tekshirish
  Future<bool> isAuthenticated() async {
    final token = await _httpService.getAccessToken();
    if (token == null || token.isEmpty) return false;

    if (_isTokenExpired(token)) {
      final refreshed = await refreshToken();
      if (refreshed == null) {
        await _httpService.clearTokens();
        return false;
      }
      return true;
    }

    return true;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);
      final exp = data['exp'] as int;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().toUtc().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  // Refresh access token using refresh token
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final refreshToken = await _httpService.getRefreshToken();
      if (refreshToken == null) return null;

      // Backend requires BOTH tokens — it derives the user id from the
      // (expired) access token's claims, then checks the refresh row in
      // the DB. Sending only refreshToken makes the server return 401.
      final accessToken = await _httpService.getAccessToken();
      if (accessToken == null) return null;

      // Backend requires BOTH tokens — it derives the user id from the
      // (expired) access token's claims, then checks the refresh row in
      // the DB. Sending only refreshToken makes the server return 401
      // because AccessToken=null can't be validated.
      final accessToken = await _httpService.getAccessToken();
      if (accessToken == null) {
        print('No access token to pair with refresh — user must login');
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _httpService.saveTokens(data['accessToken'], data['refreshToken']);
        return data;
      } else {
        await _httpService.clearTokens();
        return null;
      }
    } catch (e, st) {
      debugPrint('AuthService.refreshToken error: $e\n$st');
      return null;
    }
  }

  // Update access token only (for market registration)
  Future<void> updateAccessToken(String newAccessToken) async {
    final refreshToken = await _httpService.getRefreshToken();
    // saveTokens writes to secure storage; pass empty string if no refresh token
    await _httpService.saveTokens(newAccessToken, refreshToken ?? '');
  }

  // HttpService getter
  HttpService get httpService => _httpService;
}
