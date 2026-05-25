import 'dart:convert';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';
import '../models/profit_model.dart';

class ReportService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  ReportService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  // Get comprehensive report
  Future<Map<String, dynamic>> getComprehensiveReport(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/comprehensive?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load report',
      );
    }
  }

  // Get daily report
  Future<dynamic> getDailyReport(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/daily?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load daily report',
      );
    }
  }

  // Get period report
  Future<dynamic> getPeriodReport(DateTime start, DateTime end) async {
    final startDate = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateFormat('yyyy-MM-dd').format(end);

    final response = await _httpService.get(
      '${ApiConstants.reports}/period?start=$startDate&end=$endDate',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load period report',
      );
    }
  }

  // New methods for role-based access control

  // Get profit summary - Owner only
  Future<ProfitSummaryModel> getProfitSummary() async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/profit-summary',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Empty response body');
      }
      final decoded = jsonDecode(response.body);
      if (decoded == null) {
        throw Exception('Null response body');
      }
      return ProfitSummaryModel.fromJson(decoded as Map<String, dynamic>);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: response.statusCode == 403
          ? 'Sizga bu ma\'lumotni ko\'rish huquqi yo\'q'
          : 'Failed to load profit summary',
    );
  }

  // Get cash balance - Owner only
  Future<CashBalanceModel> getCashBalance() async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/cash-balance',
    );

    if (response.statusCode == 200) {
      return CashBalanceModel.fromJson(jsonDecode(response.body));
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: response.statusCode == 403
          ? 'Sizga bu ma\'lumotni ko\'rish huquqi yo\'q'
          : 'Failed to load cash balance',
    );
  }

  // Get daily sales list - Role-based filtering
  Future<DailySalesListModel> getDailySalesList(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/daily-sales-list?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      return DailySalesListModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load daily sales list',
      );
    }
  }

  // Kunlik savdo detallari - shu kuni sotilgan barcha tovarlar ro'yxati
  Future<List<Map<String, dynamic>>> getDailySaleItems(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _httpService.get(
      '${ApiConstants.reports}/daily-items?date=$formattedDate',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return [];
      final items = data['saleItems'] as List<dynamic>? ?? [];
      return items.map((item) => item as Map<String, dynamic>).toList();
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: switch (response.statusCode) {
        403 =>
          'Ruxsat yo\'q: Faqat Admin va Owner foydalanuvchilari hisobotlarni ko\'rishi mumkin',
        401 => 'Avtorizatsiya xatosi: Tizimga qayta kiring',
        _ => 'Kunlik savdo detallarini yuklashda xatolik',
      },
    );
  }

  /// Download the daily report as raw Excel bytes so the caller can save/open
  /// or share the file. Returns null if the response was empty or non-200.
  Future<List<int>?> downloadDailyExcel(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return await _httpService.downloadBytes(
      '${ApiConstants.reports}/daily/export?date=$formattedDate',
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard analytics endpoints (added in the 2026-05 backend update).
  //
  // Each method returns a strongly-typed object so callers don't have to deal
  // with raw maps. All three are read-only GETs that follow the same pattern
  // as the rest of the file: build the query string, call _httpService.get,
  // jsonDecode → DTO.fromJson, throw on non-200.
  // ---------------------------------------------------------------------------

  /// 7-day (or N-day) revenue / profit / check-count series for the dashboard
  /// ChartCard. Days are returned oldest-to-newest with zero rows for empty
  /// days, so the bar chart can render without gap filling.
  ///
  /// When [compare] is true the response also includes <c>previousTotal</c> —
  /// the equally-sized window immediately before the current one. The
  /// ChartCard footer uses it to display a "↑/↓ X% vs last week" delta
  /// without a second round-trip.
  Future<WeeklySeries> getWeeklySeries({
    int days = 7,
    bool compare = false,
  }) async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/weekly-series?days=$days&compare=$compare',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return const WeeklySeries(points: [], currentTotal: 0);
      }
      return WeeklySeries.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: response.statusCode == 403
          ? "Sizga bu ma'lumotni ko'rish huquqi yo'q"
          : 'Failed to load weekly series',
    );
  }

  /// Top-N products in the selected period, ranked by quantity / revenue /
  /// profit. Backs the dashboard "Eng ko'p sotilgan" card and the Reports
  /// → Top Products page. Profit is null for non-Owner callers.
  Future<TopProducts> getTopProducts({
    String period = 'month',
    String sortBy = 'quantity',
    int limit = 10,
  }) async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/top-products'
      '?period=$period&sortBy=$sortBy&limit=$limit',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return TopProducts(period: period, sortBy: sortBy, items: const []);
      }
      return TopProducts.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: response.statusCode == 403
          ? "Sizga bu ma'lumotni ko'rish huquqi yo'q"
          : 'Failed to load top products',
    );
  }

  /// Per-staff sales metrics for the period. Backs the Users list "BUGUN
  /// TUSHUM" stat and the Reports → Staff page. Includes zero-sales staff
  /// so the whole team is visible.
  Future<StaffPerformance> getStaffPerformance({String period = 'week'}) async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/staff-performance?period=$period',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return StaffPerformance(period: period, staff: const []);
      }
      return StaffPerformance.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: response.statusCode == 403
          ? "Sizga bu ma'lumotni ko'rish huquqi yo'q"
          : 'Failed to load staff performance',
    );
  }

  /// Current user's own sales metrics for the period. Backs the Seller
  /// dashboard's SellerStatsRow + PendingSaleCard. Available to all
  /// authenticated roles — each user sees only their own row.
  Future<MyPerformance> getMyPerformance({String period = 'today'}) async {
    final response = await _httpService.get(
      '${ApiConstants.reports}/my-performance?period=$period',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return MyPerformance.empty(period);
      }
      return MyPerformance.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to load my performance',
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes for the dashboard analytics endpoints.
//
// JSON shape matches the C# DTOs in MarketSystem.Application/DTOs/
// (WeeklySeriesDto, TopProductsDto, StaffPerformanceDto). All numeric fields
// use Dart `double` because the backend uses C# `decimal`. DateTime fields
// are parsed from ISO 8601 strings.
// ---------------------------------------------------------------------------

/// Safe num→double conversion: handles num, numeric strings, and null.
double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

/// Safe nullable double — preserves null (so "profit hidden from Seller"
/// doesn't get coerced to 0).
double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

DateTime _asDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) {
    return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// Mirrors `WeeklySeriesDto { List<DailyPoint> Points, decimal CurrentTotal,
/// decimal? PreviousTotal }`. [previousTotal] is null when the response was
/// requested without `?compare=true`.
class WeeklySeries {
  const WeeklySeries({
    required this.points,
    required this.currentTotal,
    this.previousTotal,
  });

  final List<DailyPoint> points;
  final double currentTotal;
  final double? previousTotal;

  /// Percent change from previous → current (e.g. +18 means current is 18 %
  /// higher). Returns null when there's no previous-period data, or when the
  /// previous total is zero (division-by-zero would yield ±infinity).
  double? get deltaPercent {
    // Snapshot once — `previousTotal` is a nullable field on this class,
    // so reading it twice would re-fetch (and not promote).
    final prev = previousTotal;
    if (prev == null || prev == 0) return null;
    return ((currentTotal - prev) / prev) * 100;
  }

  factory WeeklySeries.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    final list = raw is List ? raw : const <dynamic>[];
    return WeeklySeries(
      points: list
          .whereType<Map<String, dynamic>>()
          .map(DailyPoint.fromJson)
          .toList(),
      currentTotal: _asDouble(json['currentTotal']),
      previousTotal: _asDoubleOrNull(json['previousTotal']),
    );
  }
}

/// Mirrors `DailyPoint { DateTime Date, decimal Revenue, decimal Profit, int CheckCount }`.
class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.revenue,
    required this.profit,
    required this.checkCount,
  });

  final DateTime date;
  final double revenue;
  final double profit;
  final int checkCount;

  factory DailyPoint.fromJson(Map<String, dynamic> json) => DailyPoint(
    date: _asDate(json['date']),
    revenue: _asDouble(json['revenue']),
    profit: _asDouble(json['profit']),
    checkCount: _asInt(json['checkCount']),
  );
}

/// Mirrors `TopProductsDto { string Period, string SortBy, List<TopProductRow> Items }`.
class TopProducts {
  const TopProducts({
    required this.period,
    required this.sortBy,
    required this.items,
  });

  final String period;
  final String sortBy;
  final List<TopProductRow> items;

  factory TopProducts.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = raw is List ? raw : const <dynamic>[];
    return TopProducts(
      period: (json['period'] ?? '') as String,
      sortBy: (json['sortBy'] ?? '') as String,
      items: list
          .whereType<Map<String, dynamic>>()
          .map(TopProductRow.fromJson)
          .toList(),
    );
  }
}

/// Mirrors `TopProductRow { int Rank, string ProductId, string Name, string Category,
/// int Sellers, decimal Quantity, decimal Revenue, decimal? Profit }`.
class TopProductRow {
  const TopProductRow({
    required this.rank,
    required this.productId,
    required this.name,
    required this.category,
    required this.sellers,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });

  final int rank;
  final String productId;
  final String name;
  final String category;
  final int sellers;
  final double quantity;
  final double revenue;
  final double? profit;

  factory TopProductRow.fromJson(Map<String, dynamic> json) => TopProductRow(
    rank: _asInt(json['rank']),
    productId: (json['productId'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    category: (json['category'] ?? '').toString(),
    sellers: _asInt(json['sellers']),
    quantity: _asDouble(json['quantity']),
    revenue: _asDouble(json['revenue']),
    profit: _asDoubleOrNull(json['profit']),
  );
}

/// Mirrors `StaffPerformanceDto { string Period, List<StaffRow> Staff }`.
class StaffPerformance {
  const StaffPerformance({required this.period, required this.staff});

  final String period;
  final List<StaffRow> staff;

  factory StaffPerformance.fromJson(Map<String, dynamic> json) {
    final raw = json['staff'];
    final list = raw is List ? raw : const <dynamic>[];
    return StaffPerformance(
      period: (json['period'] ?? '') as String,
      staff: list
          .whereType<Map<String, dynamic>>()
          .map(StaffRow.fromJson)
          .toList(),
    );
  }
}

/// Mirrors `StaffRow { int Rank, string UserId, string FullName, string Role,
/// int SaleCount, decimal Revenue, decimal AverageCheck, int ShiftCount, bool IsActiveShift }`.
class StaffRow {
  const StaffRow({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.saleCount,
    required this.revenue,
    required this.averageCheck,
    required this.shiftCount,
    required this.isActiveShift,
  });

  final int rank;
  final String userId;
  final String fullName;
  final String role;
  final int saleCount;
  final double revenue;
  final double averageCheck;
  final int shiftCount;
  final bool isActiveShift;

  factory StaffRow.fromJson(Map<String, dynamic> json) => StaffRow(
    rank: _asInt(json['rank']),
    userId: (json['userId'] ?? '').toString(),
    fullName: (json['fullName'] ?? '').toString(),
    role: (json['role'] ?? '').toString(),
    saleCount: _asInt(json['saleCount']),
    revenue: _asDouble(json['revenue']),
    averageCheck: _asDouble(json['averageCheck']),
    shiftCount: _asInt(json['shiftCount']),
    isActiveShift: json['isActiveShift'] == true,
  );
}

/// Mirrors `MyPerformanceDto { string Period, string UserId, string FullName,
/// int SaleCount, decimal Revenue, decimal AverageCheck, DateTime? FirstSaleAtUtc,
/// int ShiftDurationMinutes }`. Returned by /Reports/my-performance.
class MyPerformance {
  const MyPerformance({
    required this.period,
    required this.userId,
    required this.fullName,
    required this.saleCount,
    required this.revenue,
    required this.averageCheck,
    required this.firstSaleAt,
    required this.shiftDurationMinutes,
  });

  factory MyPerformance.empty(String period) => MyPerformance(
    period: period,
    userId: '',
    fullName: '',
    saleCount: 0,
    revenue: 0,
    averageCheck: 0,
    firstSaleAt: null,
    shiftDurationMinutes: 0,
  );

  final String period;
  final String userId;
  final String fullName;
  final int saleCount;
  final double revenue;
  final double averageCheck;
  final DateTime? firstSaleAt;
  final int shiftDurationMinutes;

  /// Convenience getter: shift duration in hours, rounded down. Returns 0
  /// when there's no sale today.
  int get shiftDurationHours => shiftDurationMinutes ~/ 60;

  factory MyPerformance.fromJson(Map<String, dynamic> json) {
    final firstSaleRaw = json['firstSaleAtUtc'];
    DateTime? firstSale;
    if (firstSaleRaw is String && firstSaleRaw.isNotEmpty) {
      firstSale = DateTime.tryParse(firstSaleRaw);
    }
    return MyPerformance(
      period: (json['period'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      saleCount: _asInt(json['saleCount']),
      revenue: _asDouble(json['revenue']),
      averageCheck: _asDouble(json['averageCheck']),
      firstSaleAt: firstSale,
      shiftDurationMinutes: _asInt(json['shiftDurationMinutes']),
    );
  }
}
