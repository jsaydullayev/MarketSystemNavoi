import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
class HttpService {
  String? _accessToken;

  String get baseUrl => ApiConstants.baseUrl;

  HttpService();

  // Tokenlarni saqlash
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;
  }

  // Tokenlarni olish
  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
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

  // GET request
  Future<http.Response> get(String endpoint) async {
    final token = await getAccessToken();
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

    final response = await request.send();
    return http.Response.fromStream(response);
  }
}
