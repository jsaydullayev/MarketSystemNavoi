import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/config/app_config.dart';
import '../../../data/services/http_service.dart';
import '../domain/models/owner_detail.dart';
import '../domain/models/owner_summary.dart';
import '../domain/models/registration_request.dart';

/// Outcome bucket for an approve/reject mutation. The console screen wires
/// each case to a snackbar so the operator gets concrete feedback.
enum SuperAdminOpStatus { success, notFound, validation, unauthorized, failure }

class SuperAdminOpResult<T> {
  SuperAdminOpResult(this.status, {this.data, this.message});
  final SuperAdminOpStatus status;
  final T? data;
  final String? message;
}

/// Client for the hidden SuperAdmin console.
///
/// Every URL embeds the opaque segment from [AppConfig.superAdminConsoleSegment].
/// The backend's `SuperAdminPathGateMiddleware` rejects any other segment with
/// a flat 404 — so a misconfigured client looks identical to "nothing here"
/// and the operator must rebuild with the correct value.
class SuperAdminService {
  SuperAdminService(this._http);
  final HttpService _http;

  String get _basePath {
    const segment = AppConfig.superAdminConsoleSegment;
    return '/_sa/$segment';
  }

  /// Fetch registration requests, optionally filtered by status.
  /// Returns an empty list (not failure) if the console isn't configured —
  /// the screen shows a "not configured" banner instead.
  Future<SuperAdminOpResult<List<RegistrationRequest>>> listRequests({
    String? status,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final query = status != null && status.isNotEmpty
          ? '?status=${Uri.encodeQueryComponent(status)}'
          : '';
      final response = await _http.get('$_basePath/requests$query');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        final items = decoded
            .map((e) => RegistrationRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuperAdminOpResult(SuperAdminOpStatus.success, data: items);
      }
      return _mapNonSuccess<List<RegistrationRequest>>(response.statusCode);
    } catch (e, st) {
      debugPrint('SuperAdminService.listRequests error: $e\n$st');
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  Future<SuperAdminOpResult<List<OwnerSummary>>> listOwners() async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.get('$_basePath/owners');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        final items = decoded
            .map((e) => OwnerSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuperAdminOpResult(SuperAdminOpStatus.success, data: items);
      }
      return _mapNonSuccess<List<OwnerSummary>>(response.statusCode);
    } catch (e, st) {
      debugPrint('SuperAdminService.listOwners error: $e\n$st');
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  /// Approve a request — creates an Owner + Market + per-market CashRegister
  /// atomically on the backend. Returns the new user/market identifiers so
  /// the operator can hand the credentials to the new owner.
  Future<SuperAdminOpResult<Map<String, dynamic>>> approve({
    required String requestId,
    required String username,
    required String password,
    required String marketName,
    String? subdomain,
    String language = 'uz',
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.post(
        '$_basePath/requests/$requestId/approve',
        body: {
          'username': username,
          'password': password,
          'marketName': marketName,
          if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
          'language': language,
        },
      );
      if (response.statusCode == 200) {
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return _mapNonSuccess<Map<String, dynamic>>(
        response.statusCode,
        body: response.body,
      );
    } catch (e, st) {
      debugPrint('SuperAdminService.approve error: $e\n$st');
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  /// Real-time availability check for username / market name / subdomain.
  /// Pass `null` (or empty) for fields you don't want to check; the response
  /// mirrors that — `null` means "not asked", `true` is free, `false` is taken.
  /// When [username] is supplied and [subdomain] is omitted, the response also
  /// carries a `suggestedSubdomain` for live preview.
  Future<SuperAdminOpResult<Map<String, dynamic>>> checkAvailability({
    String? username,
    String? marketName,
    String? subdomain,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final params = <String, String>{};
      if (username != null && username.isNotEmpty) params['username'] = username;
      if (marketName != null && marketName.isNotEmpty) {
        params['marketName'] = marketName;
      }
      if (subdomain != null && subdomain.isNotEmpty) {
        params['subdomain'] = subdomain;
      }
      if (params.isEmpty) {
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: const <String, dynamic>{},
        );
      }
      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final response = await _http.get('$_basePath/check-availability?$query');
      if (response.statusCode == 200) {
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return _mapNonSuccess<Map<String, dynamic>>(response.statusCode);
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  Future<SuperAdminOpResult<void>> reject({
    required String requestId,
    required String reason,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.post(
        '$_basePath/requests/$requestId/reject',
        body: {'reason': reason},
      );
      if (response.statusCode == 200) {
        return SuperAdminOpResult(SuperAdminOpStatus.success);
      }
      return _mapNonSuccess<void>(response.statusCode, body: response.body);
    } catch (e, st) {
      debugPrint('SuperAdminService.reject error: $e\n$st');
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  // ─── Owner CRUD ─────────────────────────────────────────────────────────

  /// Fetch full owner detail (Owner + Market + live stats).
  Future<SuperAdminOpResult<OwnerDetail>> getOwnerDetail(String userId) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.get('$_basePath/owners/$userId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: OwnerDetail.fromJson(decoded),
        );
      }
      return _mapNonSuccess<OwnerDetail>(response.statusCode, body: response.body);
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  /// Manually create an owner+market (no backing registration request).
  /// Mirrors [approve]'s success payload (with `Guid.Empty` requestId).
  Future<SuperAdminOpResult<Map<String, dynamic>>> createOwner({
    required String fullName,
    required String phone,
    required String username,
    required String password,
    required String marketName,
    String? subdomain,
    String language = 'uz',
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.post(
        '$_basePath/owners',
        body: {
          'fullName': fullName,
          'phone': phone,
          'username': username,
          'password': password,
          'marketName': marketName,
          if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
          'language': language,
        },
      );
      if (response.statusCode == 200) {
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return _mapNonSuccess<Map<String, dynamic>>(
        response.statusCode,
        body: response.body,
      );
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  /// Update owner+market editable fields. Returns the refreshed [OwnerDetail].
  Future<SuperAdminOpResult<OwnerDetail>> updateOwner({
    required String userId,
    required String fullName,
    required String marketName,
    String? phone,
    String? language,
    String? subdomain,
    String? description,
    bool? ownerActive,
    bool? marketActive,
    DateTime? expiresAt,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.put(
        '$_basePath/owners/$userId',
        body: {
          'fullName': fullName,
          'marketName': marketName,
          if (phone != null) 'phone': phone,
          if (language != null) 'language': language,
          if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
          if (description != null) 'description': description,
          if (ownerActive != null) 'ownerActive': ownerActive,
          if (marketActive != null) 'marketActive': marketActive,
          if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: OwnerDetail.fromJson(decoded),
        );
      }
      return _mapNonSuccess<OwnerDetail>(response.statusCode, body: response.body);
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  /// Soft-delete owner + deactivate market. Typed confirmation: the caller
  /// must pass the EXACT current market name in [confirmMarketName] or the
  /// backend bounces with a 400.
  Future<SuperAdminOpResult<void>> deleteOwner({
    required String userId,
    required String confirmMarketName,
    required String reason,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.delete(
        '$_basePath/owners/$userId',
        body: {
          'confirmMarketName': confirmMarketName,
          'reason': reason,
        },
      );
      if (response.statusCode == 200) {
        return SuperAdminOpResult(SuperAdminOpStatus.success);
      }
      return _mapNonSuccess<void>(response.statusCode, body: response.body);
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  // ─── Market block / unblock ─────────────────────────────────────────────

  /// Administratively block a market — every login + tenant resolution
  /// attempt for it returns 423 until unblocked. Used for non-payment etc.
  Future<SuperAdminOpResult<Map<String, dynamic>>> blockMarket({
    required int marketId,
    required String reason,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.post(
        '$_basePath/markets/$marketId/block',
        body: {'reason': reason},
      );
      if (response.statusCode == 200) {
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return _mapNonSuccess<Map<String, dynamic>>(
        response.statusCode,
        body: response.body,
      );
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  Future<SuperAdminOpResult<Map<String, dynamic>>> unblockMarket({
    required int marketId,
  }) async {
    if (!AppConfig.hasSuperAdminConsole) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.failure,
        message: 'console_not_configured',
      );
    }
    try {
      final response = await _http.post(
        '$_basePath/markets/$marketId/unblock',
      );
      if (response.statusCode == 200) {
        return SuperAdminOpResult(
          SuperAdminOpStatus.success,
          data: jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return _mapNonSuccess<Map<String, dynamic>>(
        response.statusCode,
        body: response.body,
      );
    } catch (_) {
      return SuperAdminOpResult(SuperAdminOpStatus.failure);
    }
  }

  /// Translate the HTTP status into a structured outcome the UI can branch on.
  ///
  /// 404 is ambiguous: the SuperAdminPathGateMiddleware uses 404 to *hide*
  /// the console (wrong segment), but the controller also surfaces 404 when
  /// e.g. an Approve targets a request id that no longer exists. We
  /// distinguish them by whether the response body carries a JSON
  /// `message` field — the middleware writes a bare 404 with no body, the
  /// controller writes `{ message: "So'rov topilmadi." }`.
  SuperAdminOpResult<T> _mapNonSuccess<T>(int statusCode, {String? body}) {
    if (statusCode == 401 || statusCode == 403) {
      return SuperAdminOpResult(SuperAdminOpStatus.unauthorized);
    }
    if (statusCode == 404) {
      final message = _maybeMessage(body);
      return message != null
          // Genuine "resource not found" — controller produced this.
          ? SuperAdminOpResult<T>(SuperAdminOpStatus.notFound, message: message)
          // Bare 404 with no body — middleware hid the console because the
          // path segment didn't match.
          : SuperAdminOpResult<T>(
              SuperAdminOpStatus.failure,
              message: 'console_not_configured',
            );
    }
    if (statusCode == 400) {
      return SuperAdminOpResult(
        SuperAdminOpStatus.validation,
        message: _maybeMessage(body),
      );
    }
    return SuperAdminOpResult(SuperAdminOpStatus.failure);
  }

  String? _maybeMessage(String? body) {
    if (body == null) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return null;
  }
}
