import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import 'auth_service.dart';

class _RetryRequest {
  final String method;
  final String endpoint;
  final Map<String, String>? headers;
  final Object? body;

  _RetryRequest({
    required this.method,
    required this.endpoint,
    this.headers,
    this.body,
  });
}

class HttpService {
  String? _accessToken;
  AuthService? _authService;

  bool _isRefreshing = false;
  final List<_RetryRequest> _retryQueue = [];

  String get baseUrl => ApiConstants.baseUrl;

  HttpService();

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  // Tokenlarni saqlash
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    print('=== SAVING TOKENS ===');
    print('Access Token: ${accessToken.substring(0, 20)}...');
    print('Refresh Token: ${refreshToken.substring(0, 20)}...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;

    // Tekshirish: saqlanganni o'qib ko'ramiz
    final saved = prefs.getString('access_token');
    print('Token saved: ${saved != null ? "YES" : "NO"}');
    print('====================');
  }

  // Tokenlarni olish
  Future<String?> getAccessToken() async {
    if (_accessToken != null) {
      print('✅ Token from memory: ${_accessToken!.substring(0, 20)}...');
      return _accessToken;
    }
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    if (_accessToken != null) {
      print('✅ Token from SharedPreferences: ${_accessToken!.substring(0, 20)}...');
    } else {
      print('❌ NO TOKEN FOUND in SharedPreferences!');
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
  Future<http.Response> _handleResponse(http.Response response, String method, String endpoint, {Object? body}) async {
    // Agar 401 bo'lsa va refresh qilinayotgan bo'lmasa
    if (response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      print('Access token expired, attempting refresh...');

      // Tokenni refresh qilish
      final refreshed = await _authService?.refreshToken();

      _isRefreshing = false;

      if (refreshed != null) {
        print('Token refreshed successfully, retrying request...');

        // So'rovni yangi token bilan qayta yuborish
        return _retryRequest(method, endpoint, body);
      } else {
        print('Token refresh failed - user must login again');
        // Queue'dagi barcha so'rovlarni o'chirish
        _retryQueue.clear();
        return response; // 401 qaytarish
      }
    }

    return response;
  }

  // So'rovni qayta yuborish
  Future<http.Response> _retryRequest(String method, String endpoint, Object? body) async {
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

    print('=== HTTP GET ===');
    print('URL: $baseUrl$endpoint');
    print('Headers: {Content-Type: application/json${token != null ? ', Authorization: Bearer $token' : ', NO TOKEN!'}}');
    print('================');

    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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

    print('=== HTTP POST ===');
    print('URL: $baseUrl$endpoint');
    print('Headers: {Content-Type: application/json${token != null ? ', Authorization: Bearer $token' : ''}}');
    print('Body: $encodedBody');
    print('================');

    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
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

    print('=== HTTP PUT ===');
    print('URL: $baseUrl$endpoint');
    print('Has body: ${body != null}');
    if (body != null && encodedBody != null && encodedBody.length < 500) {
      print('Body: $encodedBody');
    } else if (body != null) {
      print('Body length: ${encodedBody?.length ?? 0} bytes (too large to display)');
    }
    print('================');

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

        final streamedResponse = await client.send(request);
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
    );
  }

  // DELETE request
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
    );
  }

  // PATCH request
  Future<http.Response> patch(String endpoint, {Object? body}) async {
    final response = await _performPatch(endpoint, body: body);
    return _handleResponse(response, 'PATCH', endpoint, body: body);
  }

  Future<http.Response> _performPatch(String endpoint, {Object? body}) async {
    final token = await getAccessToken();
    final encodedBody = body != null ? jsonEncode(body) : null;

    print('=== HTTP PATCH ===');
    print('URL: $baseUrl$endpoint');
    if (body != null && encodedBody != null && encodedBody.length < 500) {
      print('Body: $encodedBody');
    }
    print('================');

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

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

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

    print('=== HTTP MULTIPART UPLOAD ===');
    print('URL: $baseUrl$endpoint');
    print('File: $filePath');
    print('File size: ${(length / 1024).toStringAsFixed(2)} KB');
    print('================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Upload uchun ham 401 handle qilish
    return _handleResponse(response, 'PUT', endpoint);
  }

  // Fayl yuklab olish (byte array qaytaradi)
  Future<List<int>?> downloadBytes(String endpoint) async {
    try {
      final token = await getAccessToken();

      print('=== HTTP DOWNLOAD BYTES ===');
      print('URL: $baseUrl$endpoint');
      print('================');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Agar xato bo'lsa _handleResponse orqali tekshirish mumkin
      // Lekin byte stream bo'lgani uchun oddiy tekshiramiz
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Download bytes error: $e');
      return null;
    }
  }
}
