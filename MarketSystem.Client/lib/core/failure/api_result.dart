/// API Result Type
/// Type-safe result for operations that can fail
library;

import 'package:equatable/equatable.dart';

/// API Result class
class ApiResult<T> extends Equatable {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Success constructor
  factory ApiResult.success(T data) {
    return ApiResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Failure constructor
  factory ApiResult.failure(String error) {
    return ApiResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// Check if result has data
  bool get hasData => data != null;

  @override
  List<Object?> get props => [data, error, isSuccess];
}
