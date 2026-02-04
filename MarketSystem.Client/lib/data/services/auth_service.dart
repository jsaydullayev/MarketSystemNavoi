import 'dart:convert';
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
        body: {
          'username': username,
          'password': password,
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
  }) async {
    try {
      final response = await _httpService.post(
        ApiConstants.register,
        body: {
          'fullName': fullName,
          'username': username,
          'password': password,
          'role': role,
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
    return token != null && token.isNotEmpty;
  }
}
