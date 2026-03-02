/// Auth Repository Interface
/// Domain repository interface for authentication operations
library;

import '../entities/user_entity.dart';

/// Result type for operations that can fail
typedef ResultFuture<T> = Future<T?>;

/// Auth Repository Interface
abstract class AuthRepository {
  /// Login with email and password
  ResultFuture<UserEntity> login({
    required String email,
    required String password,
  });

  /// Register new user
  ResultFuture<UserEntity> register({
    required String userName,
    required String email,
    required String password,
  });

  /// Logout current user
  Future<void> logout();

  /// Get current logged in user
  Future<UserEntity?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Save auth token
  Future<void> saveToken(String token);

  /// Get saved token
  Future<String?> getToken();

  /// Clear auth data
  Future<void> clearAuth();
}
