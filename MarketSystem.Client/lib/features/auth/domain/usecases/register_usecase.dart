/// Register Use Case
/// Business logic for user registration
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/api_result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository_interface.dart';

/// Register Use Case Parameters
class RegisterParams extends Equatable {
  final String userName;
  final String email;
  final String password;

  const RegisterParams({
    required this.userName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [userName, email, password];
}

/// Register Use Case
class RegisterUseCase {
  final AuthRepositoryInterface repository;

  const RegisterUseCase(this.repository);

  /// Execute register use case
  Future<ApiResult<UserEntity?>> call(RegisterParams params) async {
    // Business logic: validate username
    if (params.userName.length < 3) {
      return ApiResult.failure('Username must be at least 3 characters');
    }

    // Business logic: validate email format
    if (!params.email.contains('@') || !params.email.contains('.')) {
      return ApiResult.failure('Invalid email format');
    }

    // Business logic: validate password strength
    if (params.password.length < 6) {
      return ApiResult.failure('Password must be at least 6 characters');
    }

    // Call repository
    return await repository.register(
      userName: params.userName,
      email: params.email,
      password: params.password,
    );
  }
}
