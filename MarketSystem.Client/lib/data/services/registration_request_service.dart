import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/constants/api_constants.dart';
import 'http_service.dart';

/// Outcome of a public sign-up submission.
///
/// The backend deliberately returns a *generic* 200 OK in almost every case
/// (success, duplicate phone, malformed body) so a stranger can't probe whether
/// a given phone is already in the queue. The only client-visible failure is
/// the rate limiter (HTTP 429); everything else falls back to the same friendly
/// success copy.
enum RegistrationRequestStatus {
  /// Request accepted — the SuperAdmin will review it.
  accepted,

  /// Rate-limit hit (HTTP 429). Caller should ask the user to wait.
  rateLimited,

  /// Network failure or 5xx — caller can offer "retry".
  failure,
}

class RegistrationRequestResult {
  RegistrationRequestResult(
    this.status, {
    this.message,
    this.retryAfterSeconds,
  });

  final RegistrationRequestStatus status;
  final String? message;
  final int? retryAfterSeconds;
}

class RegistrationRequestService {
  RegistrationRequestService(this._http);

  final HttpService _http;

  /// Submit a public sign-up request. Caller passes the user's full name and
  /// phone (already normalised — see the input formatter on the screen).
  Future<RegistrationRequestResult> submit({
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _http.post(
        ApiConstants.registrationRequests,
        body: {'fullName': fullName, 'phone': phone},
      );

      if (response.statusCode == 200) {
        return RegistrationRequestResult(RegistrationRequestStatus.accepted);
      }

      if (response.statusCode == 429) {
        // Backend includes retryAfterSeconds in the JSON body and a Retry-After
        // header. Prefer the body field since the header value is a string.
        final retry = _extractRetryAfter(response.body, response.headers);
        return RegistrationRequestResult(
          RegistrationRequestStatus.rateLimited,
          retryAfterSeconds: retry,
        );
      }

      // The only 4xx case the backend surfaces with a real reason is a
      // formatting hint (e.g. "Telefon raqami formati noto'g'ri"). Pass that
      // through so the user can correct it. Anything else collapses to a
      // generic accepted-style message to match the backend's behaviour.
      if (response.statusCode == 400) {
        return RegistrationRequestResult(
          RegistrationRequestStatus.accepted,
          message: _maybeExtractMessage(response.body),
        );
      }

      return RegistrationRequestResult(RegistrationRequestStatus.failure);
    } catch (e, st) {
      // Network errors surface as "failure"; the screen shows a retry option.
      // Backend availability shouldn't leak anything a normal user could enumerate.
      debugPrint('RegistrationRequestService.submit error: $e\n$st');
      return RegistrationRequestResult(RegistrationRequestStatus.failure);
    }
  }

  /// Pull a Retry-After value from the JSON body, falling back to the
  /// `Retry-After` HTTP header. Returns 60 if neither parses.
  int _extractRetryAfter(String body, Map<String, String> headers) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['retryAfterSeconds'] is num) {
        return (decoded['retryAfterSeconds'] as num).toInt();
      }
    } catch (_) {
      // body wasn't JSON — fall through
    }
    // AUDIT-1 — collapse the two-pass parse into a single tryParse so an
    // upstream change in `header` content doesn't reintroduce a race
    // where the guard succeeds and the second parse fails.
    final header = headers['retry-after'];
    final parsed = header != null ? int.tryParse(header) : null;
    return parsed ?? 60;
  }

  String? _maybeExtractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return null;
  }
}
