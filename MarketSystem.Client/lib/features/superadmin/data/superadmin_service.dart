import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/config/app_config.dart';
import '../../../data/services/http_service.dart';
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
