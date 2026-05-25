import 'dart:convert';

import 'package:http/http.dart' as http;

/// G4 — typed wrapper around the structured error envelope the backend
/// emits (`{ message, code, blockedAt?, reason? }` — see
/// `GlobalExceptionHandlerMiddleware`).
///
/// Until now every service threw `Exception('Failed to ...: ${res.body}')`
/// and every screen surfaced the raw `.toString()` of that exception in a
/// snackbar — meaning a backend rule like SHIFT_NOT_OPEN (HTTP 409) landed
/// in front of the user as `Exception: Smenani yopishda xatolik (409)` and
/// the helpful structured `code` was thrown away.
///
/// Callers should throw [ApiException.fromResponse] on any non-2xx and
/// switch on [code] to render the right localized UX (snackbar with CTA,
/// dialog, force-logout, etc.).
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.payload,
  });

  /// HTTP status code (4xx / 5xx).
  final int statusCode;

  /// Localized human-readable text the backend produced — already in the
  /// user's locale, safe to drop straight into a SnackBar.
  final String message;

  /// Stable machine-readable identifier. Canonical values (mirror
  /// `MarketSystem.API/Middleware/GlobalExceptionHandlerMiddleware.cs`):
  ///   "MARKET_BLOCKED"   — 423, the tenant was administratively blocked.
  ///   "ACCOUNT_LOCKED"   — 429, brute-force lockout tripped.
  ///   "SHIFT_NOT_OPEN"   — 409, the seller has no open shift.
  ///   "RATE_LIMITED"     — 429, IP-rate-limit fired.
  /// Null when the backend didn't include a code (legacy paths, generic 500).
  final String? code;

  /// The full decoded JSON body (when the response was JSON). Lets callers
  /// reach fields the typed constructor didn't surface (e.g. `blockedAt`
  /// for MARKET_BLOCKED), without re-parsing the response string.
  final Map<String, dynamic>? payload;

  /// Convert an HTTP response into a structured exception. Defensively
  /// parses the body — a proxy returning a non-JSON 502 doesn't crash the
  /// client; we fall back to a generic message and pass the raw text on.
  factory ApiException.fromResponse(
    http.Response res, {
    String? fallbackMessage,
  }) {
    String message = fallbackMessage ?? 'Xatolik (${res.statusCode})';
    String? code;
    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
        final m = decoded['message'];
        if (m is String && m.isNotEmpty) message = m;
        final c = decoded['code'];
        if (c is String && c.isNotEmpty) code = c;
      }
    } catch (_) {
      // Body wasn't JSON. The fallback message and status code are still useful.
    }
    return ApiException(
      statusCode: res.statusCode,
      message: message,
      code: code,
      payload: payload,
    );
  }

  /// Convenience constructors so screens can compare without remembering
  /// the exact string. The literal still has to match the backend constant.
  static const String codeShiftNotOpen = 'SHIFT_NOT_OPEN';
  static const String codeMarketBlocked = 'MARKET_BLOCKED';
  static const String codeAccountLocked = 'ACCOUNT_LOCKED';
  static const String codeRateLimited = 'RATE_LIMITED';

  bool get isShiftNotOpen => code == codeShiftNotOpen;
  bool get isConflict => statusCode == 409;

  @override
  String toString() =>
      'ApiException($statusCode${code != null ? ' / $code' : ''}): $message';
}
