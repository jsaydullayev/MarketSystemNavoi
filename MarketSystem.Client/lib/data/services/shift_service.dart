// Seller work-shift sessions — wraps the backend /api/Shifts endpoints.
//
// A shift records the time a seller actually worked. It is separate from the
// admin-set shift *permission* (ShiftStatus): this is the open/close session.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';

/// One seller work session returned by /api/Shifts.
class Shift {
  const Shift({
    required this.id,
    required this.openedAt,
    required this.closedAt,
    required this.isOpen,
    required this.durationMinutes,
  });

  final String id;

  /// Local time the shift was opened.
  final DateTime openedAt;

  /// Local time the shift was closed, or null while still open.
  final DateTime? closedAt;

  final bool isOpen;

  /// Worked minutes — to [closedAt], or to "now" while open.
  final int durationMinutes;

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: (j['id'] ?? '').toString(),
        openedAt: DateTime.tryParse(j['openedAt']?.toString() ?? '')?.toLocal() ??
            DateTime.now(),
        closedAt: j['closedAt'] == null
            ? null
            : DateTime.tryParse(j['closedAt'].toString())?.toLocal(),
        isOpen: j['isOpen'] == true,
        durationMinutes:
            j['durationMinutes'] is num ? (j['durationMinutes'] as num).toInt() : 0,
      );
}

class ShiftService {
  ShiftService({HttpService? httpService, AuthProvider? authProvider})
      : _http = httpService ?? authProvider?.httpService ?? HttpService();

  final HttpService _http;

  /// The caller's currently open shift, or null when none is open.
  /// A flaky call degrades to null rather than throwing — the dashboard card
  /// then simply shows the "open shift" state.
  Future<Shift?> getCurrentShift() async {
    try {
      final res = await _http.get('/Shifts/current');
      if (res.statusCode != 200 || res.body.isEmpty) return null;
      return Shift.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('ShiftService.getCurrentShift: $e');
      return null;
    }
  }

  /// Opens the caller's shift. Idempotent server-side — opening an
  /// already-open shift returns it unchanged.
  Future<Shift> openShift() async {
    final res = await _http.post('/Shifts/open');
    if (res.statusCode != 200) {
      // G4 — throw the typed ApiException so callers can branch on the
      // structured code (e.g. RATE_LIMITED on the open endpoint) instead
      // of pattern-matching a string. Falls back to a localized generic
      // when the body isn't JSON.
      throw ApiException.fromResponse(
        res,
        fallbackMessage: 'Smenani ochishda xatolik (${res.statusCode})',
      );
    }
    return Shift.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Closes the caller's open shift. The backend now throws
  /// `ShiftNotOpenException` → HTTP 409 with `code: SHIFT_NOT_OPEN` when
  /// there is no open shift; callers can detect that via
  /// [ApiException.isShiftNotOpen] and surface "Avval smenani oching"
  /// instead of a generic error.
  Future<Shift> closeShift() async {
    final res = await _http.post('/Shifts/close');
    if (res.statusCode != 200) {
      throw ApiException.fromResponse(
        res,
        fallbackMessage: 'Smenani yopishda xatolik (${res.statusCode})',
      );
    }
    return Shift.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
