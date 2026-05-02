/// Auth Repository Interface
/// Clean Architecture: Domain layer defines the contract
library;

import '../../../../core/failure/api_result.dart';
import '../entities/user_entity.dart';

/// Auth Repository Interface
abstract class AuthRepositoryInterface {
  /// Login with username and password
  Future<ApiResult<UserEntity?>> login({
    required String username,
    required String password,
  });

  /// Register new user
  Future<ApiResult<UserEntity?>> register({
    required String userName,
    required String email,
    required String password,
  });

  /// Logout current user
  Future<void> logout();

  /// Get current logged in user
  Future<ApiResult<UserEntity?>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
