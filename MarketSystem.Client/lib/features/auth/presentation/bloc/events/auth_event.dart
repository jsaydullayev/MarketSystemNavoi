/// Auth Events
/// Events for Auth Bloc
library;

import 'package:equatable/equatable.dart';

/// Auth Event Base
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

/// App started - check auth status
class AppStartedEvent extends AuthEvent {
  const AppStartedEvent();

  @override
  List<Object?> get props => [];
}

/// Login event
class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Register event
class RegisterEvent extends AuthEvent {
  final String userName;
  final String email;
  final String password;

  const RegisterEvent({
    required this.userName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [userName, email, password];
}

/// Logout event
class LogoutEvent extends AuthEvent {
  const LogoutEvent();

  @override
  List<Object?> get props => [];
}
