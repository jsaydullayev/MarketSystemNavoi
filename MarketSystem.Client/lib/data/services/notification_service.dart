// Lightweight unread-notification counter for the dashboard bell badge.
//
// The backend does not yet expose a `/notifications` collection (no
// persistence, no mark-as-read). For now we derive "things the Owner /
// Admin should look at" from existing data sources:
//
//   1. Low-stock products  — `/Products/GetLowStockProducts/low-stock`
//   2. Debts created today — filtered locally from `/Debts/GetAllDebts`
//
// The total is the sum of those two counts. Any individual fetch failure
// degrades to 0 for that bucket so a flaky endpoint never blanks the bell.
//
// TODO: once the backend ships a real notifications endpoint, swap the body
// of [loadUnreadCount] for a single GET and keep the same return shape.
//
// Out of scope for this pass (intentionally — a separate ticket covers it):
//   * a notifications screen / drawer
//   * mark-as-read state
//   * push notifications
//   * persistence across app restarts

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/constants/api_constants.dart';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';

class NotificationService {
  NotificationService({HttpService? httpService, AuthProvider? authProvider})
      : _http = httpService ?? authProvider?.httpService ?? HttpService();

  final HttpService _http;

  /// Returns the total number of unread "items the user should look at".
  /// Currently = low-stock product count + today's new debts count.
  /// Always returns 0 (never throws) on any error so the UI can render
  /// optimistically without a try/catch wrapper.
  Future<int> loadUnreadCount() async {
    final results = await Future.wait([
      _safeCount(_fetchLowStockCount),
      _safeCount(_fetchTodayDebtsCount),
    ]);
    return results.fold<int>(0, (a, b) => a + b);
  }

  // ---------------------------------------------------------------------------
  // Buckets — each returns an int or throws. Wrapped by `_safeCount`.
  // ---------------------------------------------------------------------------

  Future<int> _fetchLowStockCount() async {
    final response = await _http.get(
      '${ApiConstants.products}/GetLowStockProducts/low-stock',
    );
    if (response.statusCode != 200) {
      throw Exception('Low-stock fetch failed: ${response.statusCode}');
    }
    if (response.body.isEmpty) return 0;
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded.length;
    return 0;
  }

  /// Counts debts whose `createdAt` (or `debtDate` / `date`) falls on the
  /// current local calendar day. The `/Debts/GetAllDebts` endpoint does
  /// not currently accept a date filter — if it gains one later, swap to
  /// `?from=...&to=...` and drop the local filter.
  Future<int> _fetchTodayDebtsCount() async {
    final response = await _http.get('${ApiConstants.debts}/GetAllDebts');
    if (response.statusCode != 200) {
      throw Exception('Debts fetch failed: ${response.statusCode}');
    }
    if (response.body.isEmpty) return 0;
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return 0;

    final now = DateTime.now();
    int count = 0;
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final created = _parseDate(raw['createdAt'] ??
          raw['debtDate'] ??
          raw['date'] ??
          raw['saleDate']);
      if (created == null) continue;
      final local = created.toLocal();
      if (local.year == now.year &&
          local.month == now.month &&
          local.day == now.day) {
        count++;
      }
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<int> _safeCount(Future<int> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('NotificationService bucket failed: $e');
      return 0;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
