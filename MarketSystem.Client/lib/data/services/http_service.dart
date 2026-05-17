import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'auth_service.dart';

class HttpService {
  String? _accessToken;
  AuthService? _authService;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  bool _isRefreshing = false;
  // Completers for concurrent requests waiting on a token refresh
  final List<Completer<bool>> _refreshWaiters = [];

  String get baseUrl => ApiConstants.baseUrl;

  HttpService();

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    _accessToken = accessToken;
  }

  Future<String?> getAccessToken() async {
    _accessToken = await _secureStorage.read(key: _keyAccessToken);
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    _accessToken = null;
  }

  Future<http.Response> _handleResponse(
      http.Response response, String method, String endpoint,
      {Object? body}) async {
    if (response.statusCode != 401) return response;

    // Another refresh is already in progress — wait for it to complete
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshWaiters.add(completer);
      final refreshed = await completer.future;
      if (refreshed) return _retryRequest(method, endpoint, body);
      return response;
    }

    _isRefreshing = true;
    try {
      final refreshed = await _authService?.refreshToken();
      final success = refreshed != null;

      for (final w in _refreshWaiters) {
        w.complete(success);
      }
      _refreshWaiters.clear();
      _isRefreshing = false;

      if (success) return _retryRequest(method, endpoint, body);
      return response;
    } catch (e, st) {
      debugPrint('HttpService: token refresh failed: $e\n$st');
      for (final w in _refreshWaiters) {
        w.complete(false);
      }
      _refreshWaiters.clear();
      _isRefreshing = false;
      return response;
    }
  }

  Future<http.Response> _retryRequest(
      String method, String endpoint, Object? body) async {
    final token = await getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$baseUrl$endpoint');
    final encoded = body != null ? jsonEncode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: encoded);
      default:
        throw Exception('Unsupported method: $method');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final response = await _performGet(endpoint);
    return _handleResponse(response, 'GET', endpoint);
  }

  Future<http.Response> _performGet(String endpoint) async {
    final token = await getAccessToken();
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout after 30 seconds'),
    );
  }

  Future<http.Response> post(String endpoint, {Object? body}) async {
    final response = await _performPost(endpoint, body: body);
    return _handleResponse(response, 'POST', endpoint, body: body);
  }

  Future<http.Response> _performPost(String endpoint, {Object? body}) async {
    final token = await getAccessToken();
    final encodedBody = body != null ? jsonEncode(body) : null;
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout after 30 seconds'),
    );
  }

  Future<http.Response> put(String endpoint, {Object? body}) async {
    final response = await _performPut(endpoint, body: body);
    return _handleResponse(response, 'PUT', endpoint, body: body);
  }

  Future<http.Response> _performPut(String endpoint, {Object? body}) async {
    final token = await getAccessToken();
    final encodedBody = body != null ? jsonEncode(body) : null;

    // Large body uchun streaming approach
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
          onTimeout: () => throw Exception('Request timeout after 60 seconds'),
        );
        return await http.Response.fromStream(streamedResponse);
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
      onTimeout: () => throw Exception('Request timeout after 60 seconds'),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await _performDelete(endpoint);
    return _handleResponse(response, 'DELETE', endpoint);
  }

  Future<http.Response> _performDelete(String endpoint) async {
    final token = await getAccessToken();
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout after 30 seconds'),
    );
  }

  Future<http.Response> patch(String endpoint, {Object? body}) async {
    final response = await _performPatch(endpoint, body: body);
    return _handleResponse(response, 'PATCH', endpoint, body: body);
  }

  Future<http.Response> _performPatch(String endpoint, {Object? body}) async {
    final token = await getAccessToken();
    final encodedBody = body != null ? jsonEncode(body) : null;
    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout after 30 seconds'),
    );
  }

  Future<List<int>> downloadBytes(String endpoint) async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Download timeout after 60 seconds'),
    );

    final handledResponse = await _handleResponse(response, 'GET', endpoint);

    if (handledResponse.statusCode == 200) {
      return handledResponse.bodyBytes;
    }
    throw Exception('Download failed: ${handledResponse.statusCode}');
  }
}
