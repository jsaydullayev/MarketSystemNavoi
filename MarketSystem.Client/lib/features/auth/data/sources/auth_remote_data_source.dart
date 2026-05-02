/// Auth Remote Data Source
/// Data layer: API calls for authentication
library;

import 'package:dio/dio.dart';

import '../../../../core/handlers/network_handler.dart';
import '../../../../core/utils/di.dart' as di;

/// Auth Remote Data Source
class AuthRemoteDataSource {
  final NetworkHandler _networkHandler;

  AuthRemoteDataSource() : _networkHandler = di.sl<NetworkHandler>();

  /// Login API call
  Future<Response> login({
    required String username,
    required String password,
  }) async {
    return await _networkHandler.post(
      '/Auth/Login',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  /// Register API call
  Future<Response> register({
    required String userName,
    required String email,
    required String password,
  }) async {
    return await _networkHandler.post(
      '/Auth/Register',
      data: {
        'userName': userName,
        'email': email,
        'password': password,
        'confirmPassword': password,
      },
    );
  }
}
