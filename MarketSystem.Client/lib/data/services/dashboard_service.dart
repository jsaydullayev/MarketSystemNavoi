// Dashboard aggregator service.
//
// The Owner dashboard surfaces a handful of numbers — today's revenue, this
// week's profit, customer count, low-stock count, top sellers, etc. None of
// these have a single backend endpoint; instead we call the existing
// Reports / Sales / Customers / Products / Debts services in parallel and
// fold their results into a [DashboardSummary] DTO.
//
// This file is intentionally a thin aggregator: the HTTP / parsing logic
// already lives in the per-resource services, and the BLoCs/screens don't
// need to know about that fan-out. Errors are swallowed per-source so one
// flaky endpoint doesn't blank the entire screen — fields that couldn't be
// fetched fall back to safe defaults (0 / empty list).
//
// Where the API doesn't expose what we need (e.g. there's no "top products
// of the month" endpoint), we compute it locally from the daily report's
// sale items. See `_buildTopProducts` for the aggregation logic.

import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/providers/auth_provider.dart';
import 'customer_service.dart';
import 'debt_service.dart';
import 'product_service.dart';
import 'report_service.dart';

/// Snapshot of dashboard numbers for the Owner view. All fields default to
/// safe zero / empty values; per-field fetches are isolated so a single
/// failing endpoint won't blank the screen.
class DashboardSummary {
  const DashboardSummary({
    this.todayRevenue = 0,
    this.todayCheckCount = 0,
    this.todayCustomerCount = 0,
    this.todayProfit = 0,
    this.weekProfit = 0,
    this.monthRevenue = 0,
    this.customerCount = 0,
    this.topProductCount = 0,
    this.lowStockCount = 0,
    this.pendingDebtsTotal = 0,
    this.pendingDebtsCount = 0,
    this.topProducts = const [],
    this.weeklySeries = const [],
    this.weeklyDeltaPercent,
    this.topProductRows = const [],
  });

  final double todayRevenue;
  final int todayCheckCount;
  final int todayCustomerCount;
  final double todayProfit;
  final double weekProfit;
  final double monthRevenue;
  final int customerCount;
  final int topProductCount;
  final int lowStockCount;
  final double pendingDebtsTotal;
  final int pendingDebtsCount;
  /// Legacy top-3 list derived from daily-items aggregation. Kept for
  /// backwards-compat with any other consumer of [DashboardSummary]. The
  /// dashboard screen itself now prefers [topProductRows] which comes from
  /// the dedicated /Reports/top-products endpoint.
  final List<TopProductEntry> topProducts;

  /// 7-day revenue/profit time series (oldest → newest) for the ChartCard.
  /// Empty if the new endpoint is unavailable or the caller lacks access.
  final List<DailyPoint> weeklySeries;

  /// Percent change from previous-week total → current-week total. Null when
  /// the comparison data isn't available (previous week empty, endpoint
  /// failed, or `compare=true` wasn't requested). The ChartCard footer
  /// renders "↑ X%" / "↓ Y%" when present, blank when null.
  final double? weeklyDeltaPercent;

  /// Top-N products of today, ranked by quantity (descending). Comes from
  /// the /Reports/top-products?period=today endpoint. Empty on failure.
  final List<TopProductRow> topProductRows;
}

/// One row of the "Eng ko'p sotilgan" panel. [quantity] is the unit-agnostic
/// sum of `quantity` across today's sale items for this product.
class TopProductEntry {
  const TopProductEntry({required this.name, required this.quantity});

  final String name;
  final double quantity;
}

class DashboardService {
  DashboardService({required this.authProvider})
      : _reports = ReportService(authProvider: authProvider),
        _customers = CustomerService(authProvider: authProvider),
        _products = ProductService(authProvider: authProvider),
        _debts = DebtService(authProvider: authProvider);

  final AuthProvider authProvider;
  final ReportService _reports;
  final CustomerService _customers;
  final ProductService _products;
  final DebtService _debts;

  /// Aggregator: fans out to Reports/Customers/Products/Debts and folds
  /// the results into a [DashboardSummary]. Each upstream call is wrapped
  /// in its own try/catch so an individual failure degrades gracefully —
  /// missing data falls back to 0 / empty.
  Future<DashboardSummary> loadOwnerSummary() async {
    final now = DateTime.now();

    // Profit summary — Owner-only. Returns today/week/month/total profit.
    final profitFuture = _safe(() => _reports.getProfitSummary());

    // Daily report — totals for today (revenue / paid / debt / transactions).
    final dailyFuture = _safe(() => _reports.getDailyReport(now));

    // Daily sale items — needed to derive customers/check count and top products.
    final dailyItemsFuture = _safe(() => _reports.getDailyReport(now)
        .then((_) => _reports.getDailySaleItems(now)));

    // Daily sales list — used for unique customer count for today.
    final salesListFuture = _safe(() => _reports.getDailySalesList(now));

    // Period (this-month) report — for the "Bu oy aylanma" KPI.
    final monthStart = DateTime(now.year, now.month, 1);
    final monthFuture = _safe(() => _reports.getPeriodReport(monthStart, now));

    // Customer + product + debt counts.
    final customersFuture = _safe(() => _customers.getAllCustomers());
    final productsFuture = _safe(() => _products.getAllProducts());
    final debtsFuture = _safe(() => _debts.getAllDebts());

    // Dashboard analytics endpoints (added 2026-05):
    //   weekly-series  → bar chart in ChartCard
    //   top-products   → "Eng ko'p sotilgan" card (replaces local aggregation)
    // Each is _safe() wrapped so an empty / failing endpoint falls back to
    // null and the rest of the dashboard still renders.
    final weeklySeriesFuture =
        _safe(() => _reports.getWeeklySeries(days: 7, compare: true));
    final topProductsTodayFuture = _safe(() => _reports.getTopProducts(
          period: 'today',
          sortBy: 'quantity',
          limit: 3,
        ));

    final results = await Future.wait([
      profitFuture,
      dailyFuture,
      dailyItemsFuture,
      salesListFuture,
      monthFuture,
      customersFuture,
      productsFuture,
      debtsFuture,
      weeklySeriesFuture,
      topProductsTodayFuture,
    ]);

    final profit = results[0];
    final daily = results[1];
    final dailyItems = results[2] as List<Map<String, dynamic>>?;
    final salesList = results[3];
    final month = results[4];
    final customers = results[5] as List<dynamic>?;
    final products = results[6] as List<dynamic>?;
    final debts = results[7] as List<dynamic>?;
    final weeklySeries = results[8] as WeeklySeries?;
    final topProductsToday = results[9] as TopProducts?;

    // Day-of revenue & check count.
    final double todayRevenue = _num(daily, 'totalSales').toDouble();
    final int todayCheckCount = _num(daily, 'totalTransactions').toInt();

    // Today's unique customer count: count distinct customerName / customerId
    // from daily-sales-list.sales[].
    final int todayCustomerCount = _countUniqueCustomersToday(salesList);

    // Profit numbers (Owner-only endpoint — may be null for other roles).
    final double todayProfit =
        profit == null ? 0.0 : (profit.todayProfit as num).toDouble();
    final double weekProfit =
        profit == null ? 0.0 : (profit.weekProfit as num).toDouble();

    // This-month revenue.
    final double monthRevenue = _num(month, 'totalSales').toDouble();

    // Lifetime customer count = length of the GetAllCustomers list.
    final int customerCount = customers?.length ?? 0;

    // Low-stock count: backend ProductDto exposes `isLowStock`.
    final lowStock = _filterLowStock(products);
    final int lowStockCount = lowStock.length;

    // Pending debts: status == "Active" (or any non-paid). Aggregate
    // remainingDebt across active debts.
    final pendingDebts = _filterPendingDebts(debts);
    final double pendingDebtsTotal = pendingDebts.fold<double>(
      0,
      (sum, d) => sum + _numFromMap(d, 'remainingDebt').toDouble(),
    );
    final int pendingDebtsCount = pendingDebts.length;

    // Top products of the day — derived from daily-items (no dedicated
    // endpoint exists). We sum quantity per product name and take top 3.
    final topProducts = _buildTopProducts(dailyItems);

    // "Top mahsulot" KPI: total number of distinct products sold today.
    final int topProductCount = (dailyItems ?? const [])
        .map((e) => (e['productName'] ?? '').toString())
        .toSet()
        .length;

    return DashboardSummary(
      todayRevenue: todayRevenue,
      todayCheckCount: todayCheckCount,
      todayCustomerCount: todayCustomerCount,
      todayProfit: todayProfit,
      weekProfit: weekProfit,
      monthRevenue: monthRevenue,
      customerCount: customerCount,
      topProductCount: topProductCount,
      lowStockCount: lowStockCount,
      pendingDebtsTotal: pendingDebtsTotal,
      pendingDebtsCount: pendingDebtsCount,
      topProducts: topProducts,
      weeklySeries: weeklySeries?.points ?? const [],
      weeklyDeltaPercent: weeklySeries?.deltaPercent,
      topProductRows: topProductsToday?.items ?? const [],
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Generic safe wrapper: returns null on any exception. We log to debug
  /// console so a failing endpoint is still visible during development.
  Future<T?> _safe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      debugPrint('DashboardService source failed: $e\n$st');
      return null;
    }
  }

  num _num(dynamic obj, String key) {
    if (obj is Map<String, dynamic>) {
      final v = obj[key];
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
    }
    // Profit/model objects may expose fields by name. We only call this for
    // Map-shaped Report responses so Map handling is enough.
    return 0;
  }

  num _numFromMap(dynamic obj, String key) {
    if (obj is Map) {
      final v = obj[key];
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
    }
    return 0;
  }

  int _countUniqueCustomersToday(dynamic salesList) {
    if (salesList is! Map<String, dynamic>) return 0;
    final sales = salesList['sales'];
    if (sales is! List) return 0;
    final names = <String>{};
    for (final s in sales) {
      if (s is Map) {
        final name = s['customerName'];
        if (name is String && name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      }
    }
    return names.length;
  }

  List<dynamic> _filterLowStock(List<dynamic>? products) {
    if (products == null) return const [];
    return products.where((p) {
      if (p is Map<String, dynamic>) {
        final flag = p['isLowStock'];
        if (flag is bool) return flag;
        // Fallback: compute from quantity vs minThreshold.
        final qty = _numFromMap(p, 'quantity');
        final min = _numFromMap(p, 'minThreshold');
        return min > 0 && qty <= min;
      }
      return false;
    }).toList();
  }

  List<dynamic> _filterPendingDebts(List<dynamic>? debts) {
    if (debts == null) return const [];
    return debts.where((d) {
      if (d is Map) {
        final status = (d['status'] ?? '').toString().toLowerCase();
        if (status == 'paid' || status == 'cancelled') return false;
        final remaining = _numFromMap(d, 'remainingDebt');
        return remaining > 0;
      }
      return false;
    }).toList();
  }

  List<TopProductEntry> _buildTopProducts(List<Map<String, dynamic>>? items) {
    if (items == null || items.isEmpty) return const [];
    final byName = <String, double>{};
    for (final item in items) {
      final name = (item['productName'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final qty = _numFromMap(item, 'quantity').toDouble();
      byName[name] = (byName[name] ?? 0) + qty;
    }
    final sorted = byName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(3)
        .map((e) => TopProductEntry(name: e.key, quantity: e.value))
        .toList();
  }
}
