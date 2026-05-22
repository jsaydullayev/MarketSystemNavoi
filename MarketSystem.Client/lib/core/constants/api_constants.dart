import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  // =================== SERVER ===================
  // Production: all traffic goes through nginx (HTTPS termination).
  // Mobile release builds hit the domain — nginx proxies /api → API container.
  static const String _productionApiUrl = 'https://strotech.uz/api';

  // Local dev backend (dotnet run / Visual Studio F5 → http://localhost:5050).
  // Port 5050 chosen over 8080 to avoid Chrome's HSTS cache forcing HTTPS upgrades
  // on localhost:8080 (which Docker had served at some point).
  static const String _localDevApiUrl = 'http://localhost:5050/api';
  // Android emulator can't reach host via "localhost" — it must use 10.0.2.2.
  static const String _androidEmulatorDevApiUrl = 'http://10.0.2.2:5050/api';

  static String get baseUrl {
    if (kIsWeb) {
      // Debug: hit local backend directly (CORS already allows :3000/:8080/:8081).
      // Release: relative `/api` — host nginx proxies to the API container.
      return kDebugMode ? _localDevApiUrl : '/api';
    }

    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _androidEmulatorDevApiUrl;
      }
      return _localDevApiUrl;
    }
    return _productionApiUrl;
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
  // Public sign-up: anonymous POST { fullName, phone } — a SuperAdmin reviews
  // the queue in the hidden console and provisions the Owner + Market on approval.
  static const String registrationRequests = '/RegistrationRequests';
  // Audit-log read API (Plan 07 Bosqich 2/3). Lower-kebab to match the
  // backend's literal route — every other endpoint uses [controller] casing,
  // but AuditLogsController declares `[Route("api/audit-logs")]` directly.
  static const String auditLogs = '/audit-logs';

  // Auth endpoints
  static const String login = '$auth/Login';
  static const String register = '$auth/Register';
  static const String refreshToken = '$auth/RefreshToken';
  static const String logout = '$auth/Logout';
}