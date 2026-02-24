import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // =================== TEST UCHUN ===================

  // Option 1: Ngrok link (internet orqali)
  // ⚠️ HAR 2 SOATDA YANGILANG! ngrok terminalda yangi URL beradi
  // Ngrok terminalingizni ochib, yangi URL ni sherga yozing:
  // Masalan: Forwarding https://xxxx-xxxx-xxxx.ngrok-free.dev -> http://localhost:5137
  static const String _ngrokUrl = 'https://resistive-bezanty-venetta.ngrok-free.dev/api'; // ✅ Current

  // Option 2: Local Wi-Fi IP (bir xil Wi-Fi tarmog'ida)
  // IP manzilingizni bu yerga yozing (masalan: 192.168.1.5)
  static const String _localIp = 'http://192.168.1.25:5137/api'; // ✅ Updated

  // Option 3: Railway/Production URL (Haqiqiy cloud)
  // Railway URL sizi sherga yozing (masalan: https://market-system-api.up.railway.app)
  // ⚠️ O'ZGARISH: Railway dashboard'dan to'g'ri URL ni oling!
  // Mislalar: https://market-system-v1.up.railway.app/api
  //           https://your-app-name.up.railway.app/api
  static const String _prodUrl = 'https://YOUR-APP-NAME.up.railway.app/api'; // ⚠️ O'zgartiring!!!

  // Platformni aniqlab URL qaytaramiz
  static String get baseUrl {
    // TEST REJIMNI TANLANG:
    const bool useNgrok = false;       // Ngrok
    const bool useLocalIp = false;     // Local Wi-Fi IP
    const bool useProduction = true;   // ✅ Railway/Production - Cloud server

    // Default: Localhost ishlatiladi (boshqa device'lardan kirish shart emas)

    // Production (Railway) uchun
    if (useProduction) {
      if (_prodUrl != 'https://market-system-api.up.railway.app/api') {
        return _prodUrl;
      }
    }

    // Local Wi-Fi IP uchun
    if (useLocalIp) {
      return _localIp;
    }

    // Ngrok uchun
    if (useNgrok) {
      return _ngrokUrl;
    }

    // Default: Localhost (faqat shu kompyuterda ishlash uchun)
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
