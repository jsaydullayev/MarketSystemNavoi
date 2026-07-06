import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  // =================== SERVER ===================
  // Production: all traffic goes through nginx (HTTPS termination).
  // Mobile release builds hit the domain — nginx proxies /api → API container.
  // SSL restored on the new server (Let's Encrypt) 2026-06-04, so we're back
  // on HTTPS; the host nginx 80→443 redirect would upgrade plain HTTP anyway.
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

  // Product image set/remove. Backend route is `/Products/{Action}/{id}/image`.
  static String productImage(String id) => '$products/SetImage/$id/image';
  static String productImageRemove(String id) =>
      '$products/RemoveImage/$id/image';

  /// Turns the server-relative product image path ("/api/uploads/products/...")
  /// into an absolute URL the image widgets can load. The server already
  /// includes the "/api" prefix, so we join it with the API ORIGIN (baseUrl
  /// minus a trailing "/api"). Returns null for null/empty input.
  ///
  /// - mobile prod:  baseUrl "https://strotech.uz/api" → origin
  ///   "https://strotech.uz" → "https://strotech.uz/api/uploads/...".
  /// - web release:  baseUrl "/api" → origin "" → "/api/uploads/..." (same
  ///   origin, host nginx routes it to the API).
  /// - local dev:    "http://localhost:5050/api" → "http://localhost:5050" →
  ///   "http://localhost:5050/api/uploads/...".
  static String? productImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    // Already absolute (defensive — server may change shape later).
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final base = baseUrl; // ends with "/api" (or is exactly "/api")
    var origin = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    // Web release: baseUrl is the relative "/api", so origin is empty. A bare
    // relative URL isn't reliably fetched by cached_network_image, so resolve
    // it against the page origin (e.g. https://strotech.uz). On mobile, origin
    // already carries the host, so Uri.base is never consulted here.
    if (origin.isEmpty) origin = Uri.base.origin;
    final suffix = path.startsWith('/') ? path : '/$path';
    return '$origin$suffix';
  }

  // Products — Import (dry-run va haqiqiy)
  static const String productsImportPreview =
      '$products/ImportPreview/import/preview';
  static const String productsImportConfirm =
      '$products/ImportConfirm/import/confirm';

  // Categories — Excel export lives on the ProductCategories controller.
  static const String productCategoriesExportExcel =
      '$productCategories/ExportCategoriesToExcel';

  // Users — the activate / deactivate pair is the worst offender:
  // double-segment paths with a literal verb on the end. Helpers keep
  // call sites from accidentally re-introducing the original
  // `/api/Users/api/Users/...` typo.
  static String deactivateUser(dynamic id) =>
      '$users/DeactivateUser/$id/deactivate';
  static String activateUser(dynamic id) => '$users/ActivateUser/$id/activate';

  // Zakups — date-range list (ISO 8601 query) and Excel export.
  static String zakupsByDateRange(DateTime start, DateTime end) =>
      '$zakups/GetZakupsByDateRange/by-date'
      '?start=${start.toIso8601String()}&end=${end.toIso8601String()}';
  static const String zakupsExportExcel = '$zakups/ExportZakupsToExcel/export';
  static String deleteZakup(String id) => '$zakups/DeleteZakup/$id';
}
