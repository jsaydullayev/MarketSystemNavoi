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

  bool _isRefreshing = false;

  // Broadcast so multiple listeners (auth provider, app shell, login screen)
  // can react. Late events do not need to be replayed — a fresh login attempt
  // will surface the 423 again.
  static final StreamController<MarketBlockedInfo> _marketBlockedController =
      StreamController<MarketBlockedInfo>.broadcast();
  static Stream<MarketBlockedInfo> get marketBlockedStream =>
      _marketBlockedController.stream;

  String get baseUrl => ApiConstants.baseUrl;

  HttpService();

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

    if (_accessToken != null) {
      debugPrint(
          '✅ Token from SharedPreferences: ${_accessToken!.substring(0, 20)}...');
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

    // Agar 401 bo'lsa va refresh qilinayotgan bo'lmasa
    if (response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      debugPrint('Access token expired, attempting refresh...');

      // Tokenni refresh qilish
      final refreshed = await _authService?.refreshToken();

      _isRefreshing = false;

      if (refreshed != null) {
        debugPrint('Token refreshed successfully, retrying request...');

        // So'rovni yangi token bilan qayta yuborish
        return _retryRequest(method, endpoint, body);
      } else {
        debugPrint('Token refresh failed - user must login again');
        return response; // 401 qaytarish
      }
    }

    return response;
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
    final token = await getAccessToken();

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
    final token = await getAccessToken();
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
    final token = await getAccessToken();
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
    final token = await getAccessToken();

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
    final token = await getAccessToken();
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
    final token = await getAccessToken();
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
      final token = await getAccessToken();

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
