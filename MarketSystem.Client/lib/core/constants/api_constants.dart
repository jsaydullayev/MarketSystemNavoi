class ApiConstants {
  // O'zgartiring: Backend API manzili
  // Emulator uchun 10.0.2.2 ishlatiladi (kompyuterni bildiradi)
  // Real device uchun kompyuterning haqiqiy IP manzilini yozing
  static const String baseUrl = 'http://10.0.2.2:5137/api';

  // Endpoints (Controller names must match)
  static const String auth = '/Auth';
  static const String products = '/Products';
  static const String customers = '/Customers';
  static const String sales = '/Sales';
  static const String zakups = '/Zakups';
  static const String users = '/Users';
  static const String reports = '/Reports';
  static const String debts = '/Debts';

  // Auth endpoints
  static const String login = '$auth/Login';
  static const String register = '$auth/Register';
  static const String refreshToken = '$auth/Refresh';
  static const String logout = '$auth/Logout';
}
