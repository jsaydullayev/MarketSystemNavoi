/// API Interceptor
/// Handles API request/response logging and token injection
library;

import 'package:dio/dio.dart';

import '../handlers/auth_handler.dart';

/// API Interceptor class
class ApiInterceptor extends Interceptor {
  final AuthHandler _authHandler = AuthHandler();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = await _authHandler.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Log request
    _logRequest(options);

    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Log response
    _logResponse(response);

    super.onResponse(response, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Log error
    _logError(err);

    super.onError(err, handler);
  }

  void _logRequest(RequestOptions options) {
    // TODO: Implement proper logging
    print('API Request: ${options.method} ${options.uri}');
  }

  void _logResponse(Response response) {
    // TODO: Implement proper logging
    print('API Response: ${response.statusCode} ${response.requestOptions.uri}');
  }

  void _logError(DioException err) {
    // TODO: Implement proper logging
    print('API Error: ${err.message} ${err.requestOptions.uri}');
  }
}
