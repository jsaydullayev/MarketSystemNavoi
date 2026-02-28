import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // =================== SERVERS ===================
  static const String _productionUrl = 'http://103.125.217.28:8080/api'; 
  static const String _localUrl = 'http://localhost:5137/api';
  static const String _androidLocalUrl = 'http://10.0.2.2:5137/api';

  static String get baseUrl {
    // 🌍 SET TO PRODUCTION FOR KAMATERA SERVER
    const bool useProduction = true;

    if (useProduction) {
      return _productionUrl;
    }

    // Default: Localhost (faqat shu kompyuterda ishlash uchun)
    if (kIsWeb) {
      return _localUrl;
    } else if (Platform.isAndroid) {
      return _androidLocalUrl;
    } else {
      return _localUrl;
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
