import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // =================== SERVERS ===================
  static const String _productionUrl = 'http://114.29.239.156:8080/api'; // Production server (port 8080)
  static const String _dockerInternalUrl = 'http://market-system-api:8080/api'; // Docker internal service name (port 8080)
  static const String _localUrl = 'http://114.29.239.156:8080/api'; // Use server URL for local testing too
  static const String _androidLocalUrl = 'http://114.29.239.156:8080/api';
  static const String _androidRealDeviceUrl = 'http://114.29.239.156:8080/api'; // Server IP
  static const String _dockerLocalUrl = 'http://114.29.239.156:8080/api'; // Docker Compose backend port
  static const String _androidDockerLocalUrl = 'http://114.29.239.156:8080/api';

  static String get baseUrl {
    // ✅ PRODUCTION SERVER - har doim shu URL ishlaydi
    return 'http://114.29.239.156:8080/api';
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