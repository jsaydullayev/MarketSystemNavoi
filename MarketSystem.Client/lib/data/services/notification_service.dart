// Owner/Admin notification feed.
//
// The backend doesn't yet expose a `/notifications` collection (no
// persistence, no mark-as-read). Until it does, we synthesise notifications
// on the client from three existing read-only data sources:
//
//   1. /Products/GetLowStockProducts/low-stock — products at/under threshold
//   2. /Debts/GetAllDebts                       — debt sales (recent first)
//   3. /api/sales/debtors                       — customers with open debts,
//                                                 oldest-debt timestamp included
//
// "Overdue payments" don't have a server-side dueDate yet (the Debt entity
// has CreatedAt + Status but no dueDate column). We approximate by treating
// debts older than [_overdueAfterDays] as due. When a real DueDate field
// lands, swap [_isOverdue] to read it.
//
// [loadUnreadCount] returns just the total for the bell-badge red dot.
// [loadAlerts] returns the full per-item feed for the notifications screen.
// Either fetch failure for an individual bucket degrades to an empty list
// for that bucket — a flaky endpoint never blanks the whole page.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/constants/api_constants.dart';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';

/// Categories shown on the notifications screen. The screen groups items by
/// these so the "qarz savdo" pile doesn't visually compete with "kam qolgan
/// tovar"; each section gets its own header + tone.
enum AlertCategory {
  /// Low-stock products — quantity ≤ minThreshold (or backend isLowStock flag).
  lowStock,

  /// Debt sales — non-paid debts created within the [recentWindowDays] window.
  /// Shows the customer + remaining amount.
  recentDebt,

  /// Overdue debts — open debts older than [_overdueAfterDays].
  overduePayment,
}

class AlertItem {
  const AlertItem({
    required this.category,
    required this.title,
    required this.description,
    this.subjectId,
    this.amount,
    this.createdAt,
  });

  final AlertCategory category;
  final String title;
  final String description;

  /// Backing entity id (productId / debtId / customerId) — opens to the
  /// detail screen when the row is tapped. Optional so cards that don't
  /// have a target stay tappable as a no-op.
  final String? subjectId;

  /// Money amount for context (remaining debt). Null for low-stock rows.
  final double? amount;

  /// Source row's createdAt — used for sub-grouping / "X days ago" labels.
  final DateTime? createdAt;
}

/// Full notification feed snapshot. Grouped because the UI renders each
/// bucket as its own section header + card list.
class AlertFeed {
  const AlertFeed({
    this.lowStock = const [],
    this.recentDebts = const [],
    this.overdueDebts = const [],
  });

  final List<AlertItem> lowStock;
  final List<AlertItem> recentDebts;
  final List<AlertItem> overdueDebts;

  int get total => lowStock.length + recentDebts.length + overdueDebts.length;
  bool get isEmpty => total == 0;
}

class NotificationService {
  NotificationService({HttpService? httpService, AuthProvider? authProvider})
      : _http = httpService ?? authProvider?.httpService ?? HttpService();

  final HttpService _http;

  // Tuning knobs (kept local so they're easy to find).
  //
  // [_overdueAfterDays] — how old an open debt has to be before we promote
  // it from "recent" to "overdue". 14 days = a fortnight, matches the
  // typical informal credit term in Uzbek bazaars. Lower it to be more
  // aggressive; raise it once the backend ships a per-debt DueDate.
  //
  // [_recentWindowDays] — recent-debt window. We don't want to show every
  // debt the shop has ever taken; just the freshest ones the owner might
  // still be deciding whether to chase.
  static const int _overdueAfterDays = 14;
  static const int _recentWindowDays = 7;

  /// Total count for the bell badge. Cheap fallback path that doesn't
  /// require fetching the full lists; falls through to `loadAlerts().total`
  /// if any per-bucket count throws, so the bell never goes blank.
  Future<int> loadUnreadCount() async {
    try {
      final feed = await loadAlerts();
      return feed.total;
    } catch (e) {
      debugPrint('NotificationService.loadUnreadCount: $e');
      return 0;
    }
  }

  /// Full feed for the notifications screen. Always returns an [AlertFeed]
  /// — failed buckets resolve to empty lists.
  Future<AlertFeed> loadAlerts() async {
    final results = await Future.wait([
      _safeList(_fetchLowStock),
      _safeList(_fetchDebts),
    ]);

    final lowStock = results[0];
    final allDebts = results[1];

    // Split the debt list once we have it — saves a round-trip vs querying
    // the same endpoint twice with different filters.
    final now = DateTime.now();
    final recent = <AlertItem>[];
    final overdue = <AlertItem>[];
    for (final d in allDebts) {
      if (d.category == AlertCategory.overduePayment) {
        overdue.add(d);
      } else {
        // Hide debts older than the recent window so the "recent" bucket
        // doesn't double-count with overdue — overdue items only.
        if (d.createdAt != null) {
          final age = now.difference(d.createdAt!).inDays;
          if (age <= _recentWindowDays) recent.add(d);
        } else {
          recent.add(d);
        }
      }
    }

    return AlertFeed(
      lowStock: lowStock,
      recentDebts: recent,
      overdueDebts: overdue,
    );
  }

  // ---------------------------------------------------------------------------
  // Buckets
  // ---------------------------------------------------------------------------

  Future<List<AlertItem>> _fetchLowStock() async {
    final response = await _http.get(
      '${ApiConstants.products}/GetLowStockProducts/low-stock',
    );
    if (response.statusCode != 200 || response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded.whereType<Map>().map((p) {
      final name = (p['name'] ?? '').toString();
      final qty = _asNum(p['quantity']);
      final threshold = _asNum(p['minThreshold']);
      final unit = (p['unit'] ?? '').toString();
      return AlertItem(
        category: AlertCategory.lowStock,
        title: name.isEmpty ? '—' : name,
        description: threshold > 0
            ? 'Qoldiq: ${_compactNum(qty)} $unit · min ${_compactNum(threshold)} $unit'
            : 'Qoldiq: ${_compactNum(qty)} $unit',
        subjectId: (p['id'] ?? '').toString(),
      );
    }).toList();
  }

  /// Returns one [AlertItem] per non-paid debt. Each item is pre-classified
  /// into recent / overdue via [AlertCategory] based on the debt's age, so
  /// the caller doesn't need to re-walk the list.
  Future<List<AlertItem>> _fetchDebts() async {
    final response = await _http.get('${ApiConstants.debts}/GetAllDebts');
    if (response.statusCode != 200 || response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final now = DateTime.now();
    final items = <AlertItem>[];
    for (final d in decoded) {
      if (d is! Map) continue;
      final status = (d['status'] ?? '').toString().toLowerCase();
      // Paid / cancelled debts never show up as a notification.
      if (status == 'paid' || status == 'cancelled') continue;

      final remaining = _asNum(d['remainingDebt']);
      if (remaining <= 0) continue;

      final created = _parseDate(d['createdAt']);
      final customerName = (d['customerName'] ?? '').toString().trim();
      final ageDays =
          created == null ? 0 : now.difference(created).inDays;

      final isOverdue = ageDays >= _overdueAfterDays;
      items.add(AlertItem(
        category: isOverdue
            ? AlertCategory.overduePayment
            : AlertCategory.recentDebt,
        title: customerName.isEmpty ? 'Mijoz' : customerName,
        description: isOverdue
            ? 'Qarz $ageDays kunda · ${_formatUzs(remaining)} UZS'
            : 'Bugun · ${_formatUzs(remaining)} UZS',
        subjectId: (d['id'] ?? '').toString(),
        amount: remaining.toDouble(),
        createdAt: created,
      ));
    }
    // Newest first for recent, oldest first for overdue.
    items.sort((a, b) {
      if (a.category != b.category) {
        // Both buckets get their own list later; intra-bucket sort only
        // matters for tie-breaks here.
        return 0;
      }
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null || bd == null) return 0;
      return a.category == AlertCategory.overduePayment
          ? ad.compareTo(bd) // oldest first — most urgent
          : bd.compareTo(ad); // newest first
    });
    return items;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<AlertItem>> _safeList(Future<List<AlertItem>> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('NotificationService bucket failed: $e');
      return const [];
    }
  }

  num _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  String _compactNum(num v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _formatUzs(num v) {
    final n = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write(' ');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
