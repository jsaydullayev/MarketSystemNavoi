import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

/// Outcome of a refresh attempt. The old `Map?` return collapsed "the server
/// says this credential is dead" and "the network blinked" into the same
/// `null` — so a 502 during a redeploy, or 3 seconds of dropped Wi-Fi at the
/// moment the access token expired, wiped the (still perfectly valid) refresh
/// token off the device and hard-logged the user out. The two MUST be
/// distinguishable: only [rejected] may end a session.
enum RefreshOutcome {
  /// 200 — new token pair parsed and written to storage.
  renewed,

  /// The server DEFINITIVELY refused the credential (401 / 403), or there is
  /// no token pair to refresh at all. Only this outcome may clear tokens.
  rejected,

  /// Anything retryable: offline / DNS / TLS / timeout, 408, 429, any 5xx
  /// (nginx 502-504 while the API redeploys), an unreadable body, or a 409
  /// REFRESH_RACE. Tokens stay on the device; the session stays alive.
  transient,
}

class RefreshResult {
  RefreshResult(this.outcome, {this.data, this.isRace = false});

  final RefreshOutcome outcome;

  /// The AuthResponse body — non-null only when [outcome] is [renewed].
  final Map<String, dynamic>? data;

  /// True only for HTTP 409 / `REFRESH_RACE`: a concurrent caller rotated the
  /// family first and already saved the fresh pair to the SHARED storage. The
  /// caller can re-read storage and retry rather than surfacing an error.
  final bool isRace;
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
      final result = await refreshToken();
      switch (result.outcome) {
        case RefreshOutcome.renewed:
          return true;
        case RefreshOutcome.rejected:
          await _httpService.clearTokens();
          return false;
        case RefreshOutcome.transient:
          // Server/tarmoq vaqtinchalik yiqilgan — refresh token hali ham
          // haqiqiy. Sessiyani saqlab qolamiz: keyingi so'rov refresh'ni
          // qayta urinadi. Aks holda app ochilishidagi bitta 502 hamma
          // foydalanuvchini tizimdan chiqarib yuboradi.
          return true;
      }
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

  /// Refresh the access token. NEVER clears tokens — teardown belongs to the
  /// caller ([HttpService]), which is the only place that knows whether the
  /// session should actually die. See [RefreshOutcome] for the classification.
  Future<RefreshResult> refreshToken() async {
    try {
      final refreshToken = await _httpService.getRefreshToken();

      // Backend requires BOTH tokens — it derives the user id from the
      // (expired) access token's claims, then checks the refresh row in
      // the DB. Sending only refreshToken makes the server return 401
      // because AccessToken=null can't be validated.
      final accessToken = await _httpService.getAccessToken();

      if (refreshToken == null ||
          refreshToken.isEmpty ||
          accessToken == null ||
          accessToken.isEmpty) {
        // Qayta urinishning ma'nosi yo'q — yuboradigan credential yo'q.
        debugPrint('No token pair to refresh — user must login');
        return RefreshResult(RefreshOutcome.rejected);
      }

      // Client'ni O'ZIMIZ boshqaramiz. Top-level `http.post` ichida bir martalik
      // Client yaratadi va uni faqat Future TUGAGANDA yopadi — `.timeout()` esa
      // Future'ni tashlab ketadi, so'rovni bekor qilmaydi. Ya'ni qora tuynukka
      // ketgan har bir urinish bitta soket + IOClient'ni oqizib qoldirardi.
      // finally'dagi close() uchib ketayotgan so'rovni ham uzadi.
      final client = http.Client();
      final http.Response response;
      try {
        response = await client
            .post(
              Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'accessToken': accessToken,
                'refreshToken': refreshToken,
              }),
            )
            // Timeout SHART: usiz qora tuynukka ketgan ulanishda bu Future
            // hech qachon tugamaydi, HttpService'dagi single-flight
            // (_refreshInFlight) hech qachon tozalanmaydi va butun app
            // muzlab qoladi — har bir ekran cheksiz spinner ko'rsatadi.
            .timeout(const Duration(seconds: 15));
      } finally {
        client.close();
      }

      final status = response.statusCode;

      if (status == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'];
        final newRefresh = data['refreshToken'];
        if (newAccess is! String ||
            newAccess.isEmpty ||
            newRefresh is! String ||
            newRefresh.isEmpty) {
          // 200, lekin token yo'q (proxy tanani kesib qo'ygan?) — mavjud
          // tokenlar hali ham haqiqiy bo'lishi mumkin, tegmaymiz.
          debugPrint('AuthService.refreshToken: 200 without a token pair');
          return RefreshResult(RefreshOutcome.transient);
        }
        await _httpService.saveTokens(newAccess, newRefresh);
        return RefreshResult(RefreshOutcome.renewed, data: data);
      }

      // 409 REFRESH_RACE — parallel oqim tokenni bizdan oldin aylantirib
      // ulgurgan. Bu O'G'IRLIK EMAS: server oilani kuydirmaydi, biz ham
      // tokenlarni o'chirmaymiz. Chaqiruvchi umumiy xotiradan yangi tokenni
      // o'qib, so'rovni qayta yuboradi.
      if (status == 409) {
        final isRace = _errorCodeOf(response) == 'REFRESH_RACE';
        debugPrint('AuthService.refreshToken: 409 (race=$isRace)');
        return RefreshResult(RefreshOutcome.transient, isRace: isRace);
      }

      // Faqat shu ikkisi — server credential'ni aniq rad etdi (eskirgan,
      // bekor qilingan, grace'dan tashqarida qayta ishlatilgan, begona).
      if (status == 401 || status == 403) {
        debugPrint('AuthService.refreshToken: rejected ($status)');
        return RefreshResult(RefreshOutcome.rejected);
      }

      // Qolgani — 408 / 429 / 5xx (deploy paytidagi nginx 502-504) va h.k.
      // Vaqtinchalik: tokenlar joyida qoladi.
      debugPrint('AuthService.refreshToken: transient status $status');
      return RefreshResult(RefreshOutcome.transient);
    } on TimeoutException catch (e) {
      debugPrint('AuthService.refreshToken timeout: $e');
      return RefreshResult(RefreshOutcome.transient);
    } on SocketException catch (e) {
      debugPrint('AuthService.refreshToken socket error: $e');
      return RefreshResult(RefreshOutcome.transient);
    } on http.ClientException catch (e) {
      debugPrint('AuthService.refreshToken client error: $e');
      return RefreshResult(RefreshOutcome.transient);
    } catch (e, st) {
      // TLS/HandshakeException, buzuq JSON va boshqa kutilmagan xatolar.
      // Sessiyani O'LDIRMAYMIZ — faqat 401/403 shunga haqli.
      debugPrint('AuthService.refreshToken error: $e\n$st');
      return RefreshResult(RefreshOutcome.transient);
    }
  }

  /// Structured error `code` from a JSON error envelope, or null when the body
  /// isn't JSON (a proxy's HTML page) or carries no code.
  String? _errorCodeOf(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code'];
        if (code is String && code.isNotEmpty) return code;
      }
    } catch (_) {
      /* not JSON — no code to read */
    }
    return null;
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
