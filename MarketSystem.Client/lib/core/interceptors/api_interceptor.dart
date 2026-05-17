/// API Interceptor
/// Handles API request/response logging and token injection
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../handlers/auth_handler.dart';

/// API Interceptor class
class ApiInterceptor extends Interceptor {
  final AuthHandler _authHandler = AuthHandler();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authHandler.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      debugPrint('[API →] ${options.method} ${options.uri}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('[API ←] ${response.statusCode} ${response.requestOptions.uri}');
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('[API ✗] ${err.type.name} ${err.requestOptions.uri} — ${err.message}');
    }

    super.onError(err, handler);
  }
}
