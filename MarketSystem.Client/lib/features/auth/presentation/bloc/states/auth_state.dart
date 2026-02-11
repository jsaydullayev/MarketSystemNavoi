/// Auth States
/// States for Auth Bloc
library;

import 'package:equatable/equatable.dart';

/// Auth State Base
abstract class AuthState extends Equatable {
  const AuthState();
}

/// Initial state
class AuthInitialState extends AuthState {
  const AuthInitialState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class AuthLoadingState extends AuthState {
  const AuthLoadingState();

  @override
  List<Object?> get props => [];
}

/// Authenticated state
class AuthAuthenticatedState extends AuthState {
  const AuthAuthenticatedState();

  @override
  List<Object?> get props => [];
}

/// Unauthenticated state
class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();

  @override
  List<Object?> get props => [];
}

/// Error state
class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
