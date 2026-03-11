import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // =================== SERVERS ===================
  static const String _productionUrl = 'http://103.125.217.28:8080/api';
  static const String _dockerInternalUrl = 'http://market-system-api:8080/api'; // Docker internal service name
  static const String _localUrl = 'http://localhost:8080/api';
  static const String _androidLocalUrl = 'http://10.0.2.2:8080/api';
  static const String _dockerLocalUrl = 'http://localhost:8080/api';
  static const String _androidDockerLocalUrl = 'http://10.0.2.2:8080/api';

  static String get baseUrl {
    // Set to true when running inside Docker container
    const bool isRunningInDocker = true;

    const bool useProduction = true;

    const bool useDocker = false;

    // Docker container ichida ishlayotganda internal service nomini ishlatamiz
    if (isRunningInDocker) {
      return _dockerInternalUrl;
    }

    if (useProduction) {
      return _productionUrl;
    }

    if (useDocker) {
      if (kIsWeb) {
        return _dockerLocalUrl;
      } else if (Platform.isAndroid) {
        return _androidDockerLocalUrl;
      } else {
        return _dockerLocalUrl;
      }
    } else {
      // Local development without Docker (port 8080)
      if (kIsWeb) {
        return _localUrl;
      } else if (Platform.isAndroid) {
        return _androidLocalUrl;
      } else {
        return _localUrl;
      }
    }
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
  static const String refreshToken = '$auth/Refresh';
  static const String logout = '$auth/Logout';
}