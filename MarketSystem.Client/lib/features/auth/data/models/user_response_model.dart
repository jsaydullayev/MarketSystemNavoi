/// User Response Model
/// Data transfer object for user responses from API
library;

import '../../domain/entities/user_entity.dart';

/// User response DTO
class UserResponseModel {
  final int id;
  final String userName;
  final String email;
  final String? profileImage;
  final String role;
  final String token;

  UserResponseModel({
    required this.id,
    required this.userName,
    required this.email,
    this.profileImage,
    required this.role,
    required this.token,
  });

  /// Create from JSON
  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'User',
      token: json['token'] ?? '',
    );
  }

  /// Convert to entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      userName: userName,
      email: email,
      profileImage: profileImage,
      role: role,
      token: token,
    );
  }
}
