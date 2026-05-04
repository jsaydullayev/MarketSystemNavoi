import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // =================== SERVER ===================
  // Production server: 114.29.239.156, API on port 8080.
  // Web build is served from the same host (Flutter nginx container or strotech.uz),
  // so the browser uses a relative `/api` path that the host nginx proxies to the API.
  static const String _serverApiUrl = 'http://114.29.239.156:8080/api';

  // Development server URL (for local testing)
  static const String _developmentApiUrl = 'http://localhost:8080/api';

  static String get baseUrl {
    // WEB: relative URL — host nginx proxies /api/ → API container
    // MOBILE/DESKTOP: direct call to server IP
    if (kIsWeb) {
      return '/api';
    }

    // Check if we're in development environment
    // You can set this via environment variable or build configuration
    const bool isDevelopment = bool.fromEnvironment('dart.vm.product', defaultValue: false) == false;

    if (isDevelopment) {
      return _developmentApiUrl;
    }
    return _serverApiUrl;
  }



  // Endpoints (Controller names must match)
  static const String auth = '/Auth';
  static const String products = '/Products';
  static const String customers = '/Customers';
  static const String sales = '/Sales';
  static const String zakups = '/Zakups';
  static const String users = '/Users';
  static const String reports = '/Reports';
  static const String debts = '/Debts';
  static const String markets = '/Markets';
  static const String cashRegister = '/CashRegister';

  // Auth endpoints
  static const String login = '$auth/Login';
  static const String register = '$auth/Register';
  static const String refreshToken = '$auth/RefreshToken';
  static const String logout = '$auth/Logout';
}