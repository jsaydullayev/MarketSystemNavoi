import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // =================== SERVERS ===================
  static const String _productionUrl = '/api'; // Same origin (proxied by nginx)
  static const String _dockerInternalUrl = 'http://market-system-api:8080/api'; // Docker internal service name (port 8080)
  static const String _localUrl = 'http://localhost:8080/api';
  static const String _androidLocalUrl = 'http://10.0.2.2:8080/api';
  static const String _androidRealDeviceUrl = 'http://192.168.1.X:8080/api'; // Change to your PC IP
  static const String _dockerLocalUrl = 'http://localhost:8080/api'; // Docker Compose backend port
  static const String _androidDockerLocalUrl = 'http://10.0.2.2:8080/api';

  static String get baseUrl {
    // Local development - use localhost:5000
    const bool isRunningInDocker = false;

    // ✅ O'ZGARTIRISH: Local development ishlatamiz (Android uchun)
    const bool useProduction = false;

    const bool useDocker = true;

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
  static const String refreshToken = '$auth/RefreshToken';
  static const String logout = '$auth/Logout';
}