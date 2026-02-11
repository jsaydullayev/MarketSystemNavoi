/// Register Request Model
/// Data transfer object for registration requests
library;

/// Register request DTO
class RegisterRequestModel {
  final String userName;
  final String email;
  final String password;
  final String confirmPassword;

  RegisterRequestModel({
    required this.userName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }
}
