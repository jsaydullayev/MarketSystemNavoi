import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'http_service.dart';

/// Outcome of a login attempt. Lets the UI branch on WHY it failed instead
/// of collapsing every non-200 into a generic "kirish xatosi".
enum LoginOutcome {
  /// 200 — credentials valid, tokens saved, [user] populated.
  success,

  /// 401 — username or password didn't match.
  invalidCredentials,

  /// 423 — SuperAdmin has blocked the market. [blockReason] / [blockedAt]
  /// carry the audit info to show on the login screen.
  marketBlocked,

  /// 429 — rate-limited (login brute-force protection).
  rateLimited,

  /// Transport-level failure (offline, DNS, TLS, server unreachable).
  networkError,

  /// Anything else we didn't anticipate.
  unknown,
}

class LoginResult {
  LoginResult(this.outcome, {this.user, this.blockReason, this.blockedAt});
  final LoginOutcome outcome;
  final Map<String, dynamic>? user;
  final String? blockReason;
  final DateTime? blockedAt;
}

class AuthService {
  final HttpService _httpService;

  AuthService({required HttpService httpService}) : _httpService = httpService;

  // Login
  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await _httpService.post(
        ApiConstants.login,
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _httpService.saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        return LoginResult(LoginOutcome.success, user: data);
      }

      if (response.statusCode == 423) {
        // Market blocked — pull the SuperAdmin's reason out of the body so the
        // user sees WHY they can't log in instead of a generic credentials error.
        String? reason;
        DateTime? blockedAt;
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          reason = body['reason'] as String?;
          if (body['blockedAt'] is String) {
            blockedAt = DateTime.tryParse(body['blockedAt'] as String);
          }
        } catch (_) {
          /* malformed body — fall through with nulls */
        }
        return LoginResult(
          LoginOutcome.marketBlocked,
          blockReason: reason,
          blockedAt: blockedAt,
        );
      }

      if (response.statusCode == 429) {
        return LoginResult(LoginOutcome.rateLimited);
      }
      if (response.statusCode == 401) {
        return LoginResult(LoginOutcome.invalidCredentials);
      }
      return LoginResult(LoginOutcome.unknown);
    } catch (e, st) {
      debugPrint('AuthService.login error: $e\n$st');
      return LoginResult(LoginOutcome.networkError);
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
        await _httpService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
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

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
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
      // the DB. Sending only refreshToken makes the server return 401
      // because AccessToken=null can't be validated.
      final accessToken = await _httpService.getAccessToken();
      if (accessToken == null) {
        debugPrint('No access token to pair with refresh — user must login');
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
        await _httpService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
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
