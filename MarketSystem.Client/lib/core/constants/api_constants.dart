class ApiConstants {
  // O'zgartiring: Backend API manzili
  static const String baseUrl = 'http://localhost:5137/api';

  // Endpoints
  static const String auth = '/auth';
  static const String products = '/products';
  static const String customers = '/customers';
  static const String sales = '/sales';
  static const String zakups = '/zakups';
  static const String reports = '/reports';
  static const String debts = '/debts';

  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String refreshToken = '$auth/refresh';
  static const String logout = '$auth/logout';
}
