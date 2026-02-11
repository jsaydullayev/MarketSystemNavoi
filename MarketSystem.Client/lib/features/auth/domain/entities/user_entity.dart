/// User Entity
/// Core domain entity for user
library;

import 'package:equatable/equatable.dart';

/// User domain entity
class UserEntity extends Equatable {
  final int id;
  final String userName;
  final String email;
  final String? profileImage;
  final String role;
  final String token;

  const UserEntity({
    required this.id,
    required this.userName,
    required this.email,
    this.profileImage,
    required this.role,
    required this.token,
  });

  @override
  List<Object?> get props => [id, userName, email, profileImage, role, token];

  /// Empty user
  static const UserEntity empty = UserEntity(
    id: 0,
    userName: '',
    email: '',
    role: '',
    token: '',
  );

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin' || role.toLowerCase() == 'owner';

  /// Check if user is owner
  bool get isOwner => role.toLowerCase() == 'owner';

  /// Check if user is regular user
  bool get isUser => !isAdmin && !isOwner;
}
