/// Login Request Model
/// Data transfer object for login requests
library;

import '../../domain/entities/user_entity.dart';

/// Login request DTO
class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({
    required this.email,
    required this.password,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Convert from entity
  factory LoginRequestModel.fromEntity(UserEntity entity) {
    return LoginRequestModel(
      email: entity.email,
      password: entity.password,
    );
  }
}
