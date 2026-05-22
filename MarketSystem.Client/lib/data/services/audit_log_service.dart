// Owner / SuperAdmin audit-log read service.
//
// Backs the Security Journal screen (Plan 07 Bosqich 4). Two endpoints:
//
//   GET /api/audit-logs            — paged list, optional filters
//   GET /api/audit-logs/suspicious — grouped flagged events
//
// Tenant scoping is enforced server-side (Owner/Admin pinned to their own
// market; SuperAdmin sees all). This client just passes whatever filter the
// screen built — it never tries to second-guess role behaviour.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/constants/api_constants.dart';
import 'http_service.dart';

/// One audit-log row as projected by the backend.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.userId,
    required this.userName,
    required this.payload,
    required this.ipAddress,
    required this.marketId,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String action;

  /// Null for anonymous events (failed-login where the username didn't
  /// resolve to a real account) or actors that have been hard-deleted.
  final String? userId;

  /// Pre-joined from the actor's User row. Null follows [userId].
  final String? userName;

  /// JSON payload as a raw string. The screen renders a preview by trimming
  /// to one line — full inspection is left to a future detail screen.
  final String payload;

  /// Client IP captured at write time. Null when unavailable (e.g. background
  /// tasks not wired through an HTTP request).
  final String? ipAddress;

  final int? marketId;
  final DateTime createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: (json['id'] ?? '').toString(),
        entityType: (json['entityType'] ?? '').toString(),
        entityId: (json['entityId'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        userId: json['userId']?.toString(),
        userName: json['userName'] as String?,
        payload: (json['payload'] ?? '').toString(),
        ipAddress: json['ipAddress'] as String?,
        marketId: json['marketId'] is num ? (json['marketId'] as num).toInt() : null,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString())
            ?.toLocal() ??
            DateTime.now(),
      );
}

/// Standard paging envelope shared with the backend (PagedResult<T>).
class PagedAuditLogs {
  const PagedAuditLogs({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
  });

  final List<AuditLogEntry> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory PagedAuditLogs.empty({int page = 1, int size = 50}) => PagedAuditLogs(
        items: const [],
        page: page,
        size: size,
        total: 0,
        totalPages: 0,
      );

  factory PagedAuditLogs.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((m) => AuditLogEntry.fromJson(m.cast<String, dynamic>()))
            .toList()
        : <AuditLogEntry>[];
    return PagedAuditLogs(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? items.length,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Flagged group: one username hit the failed-login threshold.
class FailedLoginBurst {
  const FailedLoginBurst({
    required this.username,
    required this.count,
    required this.firstSeenUtc,
    required this.lastSeenUtc,
    required this.ipAddresses,
  });

  final String username;
  final int count;
  final DateTime firstSeenUtc;
  final DateTime lastSeenUtc;
  final List<String> ipAddresses;

  factory FailedLoginBurst.fromJson(Map<String, dynamic> json) {
    final ips = json['ipAddresses'];
    return FailedLoginBurst(
      username: (json['username'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      firstSeenUtc: DateTime.tryParse((json['firstSeenUtc'] ?? '').toString())
              ?.toLocal() ??
          DateTime.now(),
      lastSeenUtc: DateTime.tryParse((json['lastSeenUtc'] ?? '').toString())
              ?.toLocal() ??
          DateTime.now(),
      ipAddresses: ips is List
          ? ips.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}

/// Flagged group: one user issued the bulk-delete threshold of Delete actions.
class BulkDeleteBurst {
  const BulkDeleteBurst({
    required this.userId,
    required this.userName,
    required this.count,
    required this.firstSeenUtc,
    required this.lastSeenUtc,
    required this.entityTypes,
  });

  final String userId;
  final String? userName;
  final int count;
  final DateTime firstSeenUtc;
  final DateTime lastSeenUtc;
  final List<String> entityTypes;

  factory BulkDeleteBurst.fromJson(Map<String, dynamic> json) {
    final types = json['entityTypes'];
    return BulkDeleteBurst(
      userId: (json['userId'] ?? '').toString(),
      userName: json['userName'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
      firstSeenUtc: DateTime.tryParse((json['firstSeenUtc'] ?? '').toString())
              ?.toLocal() ??
          DateTime.now(),
      lastSeenUtc: DateTime.tryParse((json['lastSeenUtc'] ?? '').toString())
              ?.toLocal() ??
          DateTime.now(),
      entityTypes: types is List
          ? types.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}

/// Combined "things that look bad" payload for the Suspicious tab.
class SuspiciousReport {
  const SuspiciousReport({
    required this.failedLoginBursts,
    required this.bulkDeleteBursts,
  });

  final List<FailedLoginBurst> failedLoginBursts;
  final List<BulkDeleteBurst> bulkDeleteBursts;

  bool get isEmpty => failedLoginBursts.isEmpty && bulkDeleteBursts.isEmpty;

  factory SuspiciousReport.empty() =>
      const SuspiciousReport(failedLoginBursts: [], bulkDeleteBursts: []);

  factory SuspiciousReport.fromJson(Map<String, dynamic> json) {
    final fl = json['failedLoginBursts'];
    final bd = json['bulkDeleteBursts'];
    return SuspiciousReport(
      failedLoginBursts: fl is List
          ? fl
              .whereType<Map>()
              .map((m) => FailedLoginBurst.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
      bulkDeleteBursts: bd is List
          ? bd
              .whereType<Map>()
              .map((m) => BulkDeleteBurst.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}

class AuditLogService {
  AuditLogService({HttpService? httpService})
      : _http = httpService ?? HttpService();

  final HttpService _http;

  /// Paged audit-log lookup. All filter args are optional (null = no filter).
  Future<PagedAuditLogs> list({
    String? entityType,
    String? action,
    String? userId,
    int? marketId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int page = 1,
    int size = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (entityType != null && entityType.isNotEmpty) {
      params['entityType'] = entityType;
    }
    if (action != null && action.isNotEmpty) params['action'] = action;
    if (userId != null && userId.isNotEmpty) params['userId'] = userId;
    if (marketId != null) params['marketId'] = marketId.toString();
    // The backend expects ISO-8601 UTC; toIso8601String() emits exactly that
    // when the value carries Kind.Utc, which we ensure by calling .toUtc() here.
    if (fromUtc != null) params['from'] = fromUtc.toUtc().toIso8601String();
    if (toUtc != null) params['to'] = toUtc.toUtc().toIso8601String();

    final url = _buildUri(ApiConstants.auditLogs, params);
    try {
      final response = await _http.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) {
        return PagedAuditLogs.empty(page: page, size: size);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return PagedAuditLogs.empty(page: page, size: size);
      return PagedAuditLogs.fromJson(decoded.cast<String, dynamic>());
    } catch (e) {
      debugPrint('AuditLogService.list failed: $e');
      return PagedAuditLogs.empty(page: page, size: size);
    }
  }

  /// Suspicious-activity report. Null [marketId] is SuperAdmin-only —
  /// non-SuperAdmin callers are pinned to their tenant by the server
  /// regardless of what we send.
  Future<SuspiciousReport> getSuspicious({int? marketId}) async {
    final params = <String, String>{};
    if (marketId != null) params['marketId'] = marketId.toString();

    final url = _buildUri('${ApiConstants.auditLogs}/suspicious', params);
    try {
      final response = await _http.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) {
        return SuspiciousReport.empty();
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return SuspiciousReport.empty();
      return SuspiciousReport.fromJson(decoded.cast<String, dynamic>());
    } catch (e) {
      debugPrint('AuditLogService.getSuspicious failed: $e');
      return SuspiciousReport.empty();
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────

  /// HttpService.get accepts a relative path; the absolute base URL is
  /// resolved internally. We just glue the query string.
  String _buildUri(String path, Map<String, String> params) {
    if (params.isEmpty) return path;
    final qs = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$path?$qs';
  }
}
