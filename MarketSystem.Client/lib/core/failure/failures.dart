/// Failure models
/// Represents different types of failures/errors
library;

import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server failure - HTTP errors
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

/// Network failure - Connection issues
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Cache failure - Local storage issues
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Authentication failure - Auth errors
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Validation failure - Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Not found failure - Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Ma\'lumot topilmadi'])
      : super(message);
}

/// Permission denied failure
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([
    String message = 'Sizda bu amalni bajarish huquqi yo\'q',
  ]) : super(message);
}

/// Unknown failure - Unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Noma\'lum xatolik yuz berdi'])
      : super(message);
}
