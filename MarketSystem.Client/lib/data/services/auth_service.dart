import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'http_service.dart';

class AuthService {
  final HttpService _httpService;

  AuthService({required HttpService httpService}) : _httpService = httpService;

  // Login
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final requestBody = {
        'username': username,
        'password': password,
      };

      print('=== LOGIN DEBUG ===');
      print('URL: ${ApiConstants.baseUrl}${ApiConstants.login}');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await _httpService.post(
        ApiConstants.login,
        body: requestBody,
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Tokenlarni saqlash
        await _httpService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );

        return data;
      } else {
        print('Login failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
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

        // Tokenlarni saqlash
        await _httpService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );

        return data;
      }
      return null;
    } catch (e) {
      print('Register error: $e');
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
        body: {
          'refreshToken': refreshToken,
        },
      );

      await _httpService.clearTokens();
      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      await _httpService.clearTokens();
      return true;
    }
  }

  // Token borligini tekshirish
  Future<bool> isAuthenticated() async {
    final token = await _httpService.getAccessToken();
    if (token == null || token.isEmpty) return false;

    if (_isTokenExpired(token)) {
      print('Access token expired, attempting refresh...');
      final refreshed = await refreshToken();

      if (refreshed == null) {
        print('Token refresh failed - user must login again');
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
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  // ✅ Refresh access token using refresh token
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final refreshToken = await _httpService.getRefreshToken();
      if (refreshToken == null) {
        print('No refresh token available');
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      print('Refresh Token Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _httpService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        print('Token refreshed successfully');
        return data;
      } else {
        print('Refresh token expired, user must login again');
        await _httpService.clearTokens();
        return null;
      }
    } catch (e) {
      print('Refresh token error: $e');
      return null;
    }
  }

  // ✅ NEW: Update access token only (for market registration)
  Future<void> updateAccessToken(String newAccessToken) async {
    try {
      // Get current refresh token
      final refreshToken = await _httpService.getRefreshToken();

      if (refreshToken != null) {
        // Save new access token with existing refresh token
        await _httpService.saveTokens(newAccessToken, refreshToken);
      } else {
        // Fallback: save only access token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccessToken);
      }
    } catch (e) {
      print('Error updating access token: $e');
      rethrow;
    }
  }

  // HttpService getter
  HttpService get httpService => _httpService;
}
