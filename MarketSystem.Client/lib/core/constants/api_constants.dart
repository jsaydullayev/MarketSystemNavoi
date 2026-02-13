import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // Platformni aniqlab URL qaytaramiz
  static String get baseUrl {
    if (kIsWeb) {
      // Web - localhost
      return 'http://localhost:5137/api';
    } else if (Platform.isAndroid) {
      // Android Emulator - 10.0.2.2
      return 'http://10.0.2.2:5137/api';
    } else {
      // iOS yoki Real device - localhost (simulator) yoki haqiqiy IP
      // TODO: Real device uchun IP manzilini o'zgartiring
      return 'http://localhost:5137/api';
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

  // Auth endpoints
  static const String login = '$auth/Login';
  static const String register = '$auth/Register';
  static const String refreshToken = '$auth/Refresh';
  static const String logout = '$auth/Logout';
}
