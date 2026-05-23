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
  static const String productCategories = '/ProductCategories';
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

  // ── Sub-route helpers ───────────────────────────────────────────
  // These exist so call sites don't have to memorise the exact backend
  // path shape (some are `/Controller/Action/{id}/{verb}`, some are
  // flat). One place to fix when a route moves.

  // Customers — by-phone and pre-delete-info are looked up frequently
  // and the URL shape (`GetX/segment/{value}`) is non-obvious.
  static String customerByPhone(String phone) =>
      '$customers/GetCustomerByPhone/phone/$phone';
  static String customerDeleteInfo(String id) =>
      '$customers/GetCustomerDeleteInfo/$id/delete-info';

  // Products — Excel export ships through a doubly-segmented route.
  static const String productsExportExcel =
      '$products/ExportProductsToExcel/export';

  // Categories — Excel export lives on the ProductCategories controller.
  static const String productCategoriesExportExcel =
      '$productCategories/ExportCategoriesToExcel';

  // Users — the activate / deactivate pair is the worst offender:
  // double-segment paths with a literal verb on the end. Helpers keep
  // call sites from accidentally re-introducing the original
  // `/api/Users/api/Users/...` typo.
  static String deactivateUser(dynamic id) =>
      '$users/DeactivateUser/$id/deactivate';
  static String activateUser(dynamic id) =>
      '$users/ActivateUser/$id/activate';

  // Zakups — date-range list (ISO 8601 query) and Excel export.
  static String zakupsByDateRange(DateTime start, DateTime end) =>
      '$zakups/GetZakupsByDateRange/by-date'
      '?start=${start.toIso8601String()}&end=${end.toIso8601String()}';
  static const String zakupsExportExcel = '$zakups/ExportZakupsToExcel/export';
}