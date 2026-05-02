/// Auth Repository Implementation
/// Data layer: Implements AuthRepositoryInterface
library;

import '../../../../core/failure/api_result.dart';
import '../../../../core/handlers/network_handler.dart';
import '../../../../core/handlers/auth_handler.dart';
import '../../../../core/utils/di.dart' as di;
import '../models/user_response_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository_interface.dart';

/// Auth Repository Implementation
class AuthRepositoryImpl implements AuthRepositoryInterface {
  final NetworkHandler _networkHandler;
  final AuthHandler _authHandler;

  AuthRepositoryImpl()
      : _networkHandler = di.sl<NetworkHandler>(),
        _authHandler = di.sl<AuthHandler>();

  @override
  Future<ApiResult<UserEntity?>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _networkHandler.post(
        '/Auth/Login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final userResponse = UserResponseModel.fromJson(response.data);
        await _authHandler.saveToken(userResponse.token);
        await _authHandler.saveUserId(userResponse.id);
        await _authHandler.saveUserName(userResponse.userName);
        await _authHandler.saveUserRole(userResponse.role);
        return ApiResult.success(userResponse.toEntity());
      }

      return ApiResult.failure('Login failed');
    } catch (e) {
      return ApiResult.failure('Network error: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<UserEntity?>> register({
    required String userName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _networkHandler.post(
        '/Auth/Register',
        data: {
          'userName': userName,
          'email': email,
          'password': password,
          'confirmPassword': password,
        },
      );

      if (response.statusCode == 200) {
        final userResponse = UserResponseModel.fromJson(response.data);
        return ApiResult.success(userResponse.toEntity());
      }

      return ApiResult.failure('Registration failed');
    } catch (e) {
      return ApiResult.failure('Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    await _authHandler.clearAuth();
  }

  @override
  Future<ApiResult<UserEntity?>> getCurrentUser() async {
    final userId = await _authHandler.getUserId();
    final userName = await _authHandler.getUserName();
    final role = await _authHandler.getUserRole();

    if (userId != null && userName != null && role != null) {
      return ApiResult.success(UserEntity(
        id: userId!,
        userName: userName!,
        email: userName,
        profileImage: null,
        role: role!,
        token: '',
      ));
    }

    return ApiResult.failure('No user logged in');
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _authHandler.getToken();
    return token != null && token.isNotEmpty;
  }
}
