import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import 'auth_service.dart';

/// Carries the reason a market was administratively blocked. Surfaced through
/// [HttpService.marketBlockedStream] so the app shell can show a dedicated
/// "contact admin" screen on top of whichever route the user was on.
class MarketBlockedInfo {
  MarketBlockedInfo({
    required this.message,
    this.reason,
    this.blockedAt,
  });

  final String message;
  final String? reason;
  final DateTime? blockedAt;
}

class HttpService {
  String? _accessToken;
  AuthService? _authService;

  /// Single-flight token refresh. When the access token expires and a burst
  /// of requests fire in parallel (e.g. the dashboard's ~12 concurrent
  /// loads), every one of them gets a 401 at nearly the same instant. They
  /// must all funnel through ONE refresh and then retry — never race.
  ///
  /// The previous implementation used a `bool _isRefreshing` flag: the first
  /// 401 set it and refreshed, but every other concurrent 401 saw the flag
  /// already true, skipped the refresh block entirely, and returned its raw
  /// 401. That's why a parallel dashboard load rendered all-zeros after a
  /// token expiry — only one request was ever retried.
  ///
  /// Holds the in-flight refresh Future; concurrent 401s await the same one.
  /// Cleared when the refresh settles so a later expiry can refresh again.
  Future<bool>? _refreshInFlight;

  // Broadcast so multiple listeners (auth provider, app shell, login screen)
  // can react. Late events do not need to be replayed — a fresh login attempt
  // will surface the 423 again.
  static final StreamController<MarketBlockedInfo> _marketBlockedController =
      StreamController<MarketBlockedInfo>.broadcast();
  static Stream<MarketBlockedInfo> get marketBlockedStream =>
      _marketBlockedController.stream;

  String get baseUrl => ApiConstants.baseUrl;

  // ── Singleton ───────────────────────────────────────────────
  // HttpService MUST be a singleton. The DI wiring calls
  // `setAuthService()` exactly once (di.dart) so the 401 / refresh path
  // has an AuthService to call. But the data services
  // (ReportService, CustomerService, DebtService, …) each did
  // `_httpService = httpService ?? HttpService()` — creating their OWN
  // fresh instance whose `_authService` was null. Those instances could
  // never refresh a token: the dashboard's requests would 401 and fail,
  // while NotificationService (which used the wired instance) succeeded.
  // That's the "data only appears on the 2nd refresh" bug — the wired
  // instance refreshed the token as a side effect, so the next load
  // found a valid token already in storage.
  //
  // A factory-singleton means every `HttpService()` call — no matter
  // which service makes it — returns the one wired instance, with a
  // shared `_authService` and a shared single-flight `_refreshInFlight`.
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  // Tokenlarni saqlash
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    debugPrint('=== SAVING TOKENS ===');
    debugPrint('Access Token: ${accessToken.substring(0, 20)}...');
    debugPrint('Refresh Token: ${refreshToken.substring(0, 20)}...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;

    // Tekshirish: saqlanganni o'qib ko'ramiz
    final saved = prefs.getString('access_token');
    debugPrint('Token saved: ${saved != null ? "YES" : "NO"}');
    debugPrint('====================');
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    if (_accessToken case final token?) {
      debugPrint(
          '✅ Token from SharedPreferences: ${token.substring(0, 20)}...');
    } else {
      debugPrint('❌ NO TOKEN FOUND!');
    }
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // Tokenlarni tozalash
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
  }

  /// True when the JWT's `exp` claim is in the past (with a 15-second
  /// leeway so a token about to expire mid-request is renewed now). On any
  /// decode failure returns false — we then proceed and let the reactive
  /// 401 handler deal with it rather than blocking on an unreadable token.
  bool _isAccessTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! int) return false;
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now()
          .toUtc()
          .isAfter(expiry.subtract(const Duration(seconds: 15)));
    } catch (_) {
      return false;
    }
  }

  /// Returns a non-expired access token, refreshing PROACTIVELY (single-
  /// flight) when the stored one has already expired.
  ///
  /// This is the key fix for the "dashboard intermittently shows no data"
  /// bug: a screen like the dashboard fires ~12 requests in parallel. With
  /// a stale token they would ALL 401 at once, and the reactive refresh +
  /// retry path is racy — requests whose 401 lands after the shared refresh
  /// future already settled would start a second refresh or fail to retry.
  /// Checking expiry up-front means the dozen requests funnel through ONE
  /// refresh BEFORE they're sent, so there's no 401-storm to recover from.
  ///
  /// `/Auth/` endpoints skip this — Login carries no token and RefreshToken
  /// must not recurse.
  Future<String?> _freshAccessToken(String endpoint) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return token;
    if (endpoint.contains('/Auth/')) return token;
    if (_isAccessTokenExpired(token)) {
      debugPrint('Access token expired — proactive refresh before $endpoint');
      final ok = await _refreshTokenOnce();
      if (ok) return await getAccessToken();
    }
    return token;
  }

  // ✅ 401 xatolikni qayta ishlash va token refresh
  Future<http.Response> _handleResponse(
      http.Response response, String method, String endpoint,
      {Object? body}) async {
    // 423 Locked = market was blocked by a SuperAdmin. The session is now
    // unusable — wipe tokens so the user can't keep retrying on a doomed
    // JWT, and emit the reason so the app shell can pop to a block screen.
    // Parse defensively: an upstream proxy returning 423 with no JSON body
    // shouldn't crash the client.
    if (response.statusCode == 423) {
      MarketBlockedInfo info;
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        info = MarketBlockedInfo(
          message: decoded['message'] as String? ??
              'Do\'kon administrator tomonidan bloklangan.',
          reason: decoded['reason'] as String?,
          blockedAt: decoded['blockedAt'] is String
              ? DateTime.tryParse(decoded['blockedAt'] as String)
              : null,
        );
      } catch (_) {
        info = MarketBlockedInfo(
          message: 'Do\'kon administrator tomonidan bloklangan.',
        );
      }
      await clearTokens();
      _marketBlockedController.add(info);
      return response;
    }

    // 401 — the access token expired. Refresh once (shared across every
    // concurrent 401), then retry THIS request with the fresh token.
    //
    // Auth endpoints are excluded: a 401 from Login / RefreshToken / Logout
    // is a genuine credential failure, not an expiry to transparently paper
    // over — retrying it would just loop.
    if (response.statusCode == 401 && !endpoint.contains('/Auth/')) {
      debugPrint('Access token expired (401 on $endpoint) — refreshing...');

      final refreshed = await _refreshTokenOnce();

      if (refreshed) {
        debugPrint('Token refreshed — retrying $method $endpoint');
        return _retryRequest(method, endpoint, body);
      }
      debugPrint('Token refresh failed — user must login again');
      return response; // surface the 401 so the app shell can route to login
    }

    return response;
  }

  /// Refresh the access token, shared single-flight across concurrent 401s.
  /// The first caller starts the refresh; everyone else awaits the same
  /// Future. Returns true when the token was renewed.
  Future<bool> _refreshTokenOnce() {
    return _refreshInFlight ??= _doRefresh();
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshed = await _authService?.refreshToken();
      return refreshed != null;
    } catch (e) {
      debugPrint('HttpService._doRefresh error: $e');
      return false;
    } finally {
      // Clear so a later (post-batch) expiry can trigger a fresh refresh.
      _refreshInFlight = null;
    }
  }

  // So'rovni qayta yuborish
  Future<http.Response> _retryRequest(
      String method, String endpoint, Object? body) async {
    final token = await getAccessToken();

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
      case 'POST':
        final encodedBody = body != null ? jsonEncode(body) : null;
        return http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        );
      case 'PUT':
        final encodedBody = body != null ? jsonEncode(body) : null;
        return http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        );
      case 'DELETE':
        return http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
      case 'PATCH':
        final encodedBody = body != null ? jsonEncode(body) : null;
        return http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        );
      default:
        throw Exception('Unsupported method: $method');
    }
  }

  // GET request
  Future<http.Response> get(String endpoint) async {
    final response = await _performGet(endpoint);
    return _handleResponse(response, 'GET', endpoint);
  }

  Future<http.Response> _performGet(String endpoint) async {
    final token = await _freshAccessToken(endpoint);

    debugPrint('=== HTTP GET ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint(
        'Headers: {Content-Type: application/json${token != null ? ', Authorization: Bearer $token' : ', NO TOKEN!'}}');
    debugPrint('================');

    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timeout after 30 seconds');
      },
    );
  }

  // POST request
  Future<http.Response> post(String endpoint, {Object? body}) async {
    final response = await _performPost(endpoint, body: body);
    return _handleResponse(response, 'POST', endpoint, body: body);
  }

  Future<http.Response> _performPost(String endpoint, {Object? body}) async {
    final token = await _freshAccessToken(endpoint);
    final encodedBody = body != null ? jsonEncode(body) : null;

    debugPrint('=== HTTP POST ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint(
        'Headers: {Content-Type: application/json${token != null ? ', Authorization: Bearer $token' : ''}}');
    debugPrint('Body: $encodedBody');
    debugPrint('================');

    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timeout after 30 seconds');
      },
    );
  }

  // PUT request
  Future<http.Response> put(String endpoint, {Object? body}) async {
    final response = await _performPut(endpoint, body: body);
    return _handleResponse(response, 'PUT', endpoint, body: body);
  }

  Future<http.Response> _performPut(String endpoint, {Object? body}) async {
    final token = await _freshAccessToken(endpoint);
    final encodedBody = body != null ? jsonEncode(body) : null;

    debugPrint('=== HTTP PUT ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint('Has body: ${body != null}');
    debugPrint('Has token: ${token != null}');
    if (body != null && encodedBody != null && encodedBody.length < 500) {
      debugPrint('Body: $encodedBody');
    } else if (body != null) {
      debugPrint(
          'Body length: ${encodedBody?.length ?? 0} bytes (too large to display)');
    }
    debugPrint('================');

    // For large bodies, use a different approach to avoid encoding issues
    if (encodedBody != null && encodedBody.length > 100000) {
      final client = http.Client();
      try {
        final request = http.Request('PUT', Uri.parse('$baseUrl$endpoint'));
        request.headers.addAll({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });
        request.body = encodedBody;

        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw Exception('Request timeout after 60 seconds');
          },
        );
        final response = await http.Response.fromStream(streamedResponse);
        return response;
      } finally {
        client.close();
      }
    }

    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw Exception('Request timeout after 60 seconds');
      },
    );
  }

  // DELETE request (optionally with a JSON body — used by the SuperAdmin
  // owner-delete endpoint, which carries a typed-confirmation payload).
  Future<http.Response> delete(String endpoint, {Object? body}) async {
    final response = await _performDelete(endpoint, body);
    return _handleResponse(response, 'DELETE', endpoint, body: body);
  }

  Future<http.Response> _performDelete(String endpoint, Object? body) async {
    final token = await _freshAccessToken(endpoint);

    final fullUrl = '$baseUrl$endpoint';
    debugPrint('=== HTTP DELETE ===');
    debugPrint('Full URL: $fullUrl');
    debugPrint('==================');

    // The http package's delete() convenience method doesn't accept a body, so
    // hand-roll the request when one is supplied. RFC 7231 permits a body on
    // DELETE — ASP.NET Core accepts it with [FromBody].
    if (body == null) {
      return http.delete(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    }

    final request = http.Request('DELETE', Uri.parse(fullUrl));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.body = jsonEncode(body);
    final streamed = await http.Client().send(request);
    return http.Response.fromStream(streamed);
  }

  // PATCH request
  Future<http.Response> patch(String endpoint, {Object? body}) async {
    final response = await _performPatch(endpoint, body: body);
    return _handleResponse(response, 'PATCH', endpoint, body: body);
  }

  Future<http.Response> _performPatch(String endpoint, {Object? body}) async {
    final token = await _freshAccessToken(endpoint);
    final encodedBody = body != null ? jsonEncode(body) : null;

    debugPrint('=== HTTP PATCH ===');
    debugPrint('URL: $baseUrl$endpoint');
    if (body != null && encodedBody != null && encodedBody.length < 500) {
      debugPrint('Body: $encodedBody');
    }
    debugPrint('================');

    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
    );
  }

  // Multipart file upload (for images, etc.)
  Future<http.Response> uploadFile(
    String endpoint, {
    required String filePath,
    String? fileFieldName,
    Map<String, String>? fields,
  }) async {
    final token = await _freshAccessToken(endpoint);
    final file = File(filePath);

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl$endpoint'),
    );

    // Add headers - use addAll instead of direct assignment
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add file
    final fileStream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(
      fileFieldName ?? 'file',
      fileStream,
      length,
      filename: filePath.split('/').last,
    );
    request.files.add(multipartFile);

    // Add additional fields
    if (fields != null) {
      fields.forEach((key, value) {
        request.fields[key] = value;
      });
    }

    debugPrint('=== HTTP MULTIPART UPLOAD ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint('File: $filePath');
    debugPrint('File size: ${(length / 1024).toStringAsFixed(2)} KB');
    debugPrint('================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Upload uchun ham 401 handle qilish
    return _handleResponse(response, 'PUT', endpoint);
  }

  // Fayl yuklab olish (byte array qaytaradi)
  Future<List<int>?> downloadBytes(String endpoint) async {
    try {
      final token = await _freshAccessToken(endpoint);

      debugPrint('=== HTTP DOWNLOAD BYTES ===');
      debugPrint('URL: $baseUrl$endpoint');
      debugPrint('================');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // 401 xatolikni handle qilish
      final handledResponse = await _handleResponse(response, 'GET', endpoint);

      if (handledResponse.statusCode == 200) {
        return handledResponse.bodyBytes;
      }
      debugPrint('Download failed with status: ${handledResponse.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Download bytes error: $e');
      return null;
    }
  }
}
