/// Login Use Case
/// Business logic for user authentication
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/api_result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository_interface.dart';

/// Login Use Case Parameters
class LoginParams extends Equatable {
  final String username;
  final String password;

  const LoginParams({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// Login Use Case
class LoginUseCase {
  final AuthRepositoryInterface repository;

  const LoginUseCase(this.repository);

  /// Execute login use case
  Future<ApiResult<UserEntity?>> call(LoginParams params) async {
    // Business logic: validate username
    if (params.username.isEmpty) {
      return ApiResult.failure('Username is required');
    }

    // Business logic: validate password length
    if (params.password.length < 6) {
      return ApiResult.failure('Password must be at least 6 characters');
    }

    // Call repository
    return await repository.login(
      username: params.username,
      password: params.password,
    );
  }
}
