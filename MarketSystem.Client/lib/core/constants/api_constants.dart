import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // =================== TEST UCHUN ===================

  // Option 1: Ngrok link (internet orqali)
  // Ngrok domain sizi sherga yozing (masalan: https://my-shop.ngrok-free.app)
  static const String _ngrokUrl = 'https://resistive-bezanty-venetta.ngrok-free.dev/api'; // ⚠️ 2 soatda o'zgaradi!

  // Option 2: Local Wi-Fi IP (bir xil Wi-Fi tarmog'ida)
  // IP manzilingizni bu yerga yozing (masalan: 192.168.1.5)
  static const String _localIp = 'http://192.168.1.5:5137/api';

  // Option 3: Railway/Production URL (Haqiqiy cloud)
  // Railway URL sizi sherga yozing (masalan: https://market-system-api.up.railway.app)
  static const String _prodUrl = 'https://market-system-api.up.railway.app/api';

  // Platformni aniqlab URL qaytaramiz
  static String get baseUrl {
    // TEST REJIMNI TANLANG:
    const bool useNgrok = false;      // true = Ngrok, false = Local Wi-Fi (⚠️ localStorage issue!)
    const bool useLocalIp = false;    // true = Local Wi-Fi, false = Emulator
    const bool useProduction = false;  // true = Railway/Production

    // Production (Railway) uchun
    if (useProduction) {
      if (_prodUrl != 'https://market-system-api.up.railway.app/api') {
        return _prodUrl;
      }
    }

    // Ngrok uchun
    if (useNgrok) {
      if (_ngrokUrl != 'https://your-ngrok-link.ngrok-free.app/api') {
        return _ngrokUrl;
      }
    }

    // Local Wi-Fi IP uchun
    if (useLocalIp) {
      if (_localIp != 'http://192.168.1.5:5137/api') {
        return _localIp;
      }
    }

    // Default: Platform asosida
    if (kIsWeb) {
      return 'http://localhost:5137/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5137/api';
    } else {
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
  static const String markets = '/Markets';
  static const String cashRegister = '/CashRegister';

  // Auth endpoints
  static const String login = '$auth/Login';
  static const String register = '$auth/Register';
  static const String refreshToken = '$auth/Refresh';
  static const String logout = '$auth/Logout';
}
