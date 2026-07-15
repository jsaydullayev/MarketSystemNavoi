// Reports hub screen — migrated to the new design system.
//
// Layout follows HTML demo page 9.1 (`#page-rpt-hub`):
// - Period segmented control (Bugun / Kecha / 7 kun / Oy / Custom)
// - Dark navy "JAMI · X-KUNLIK AYLANMA" gradient hero with total turnover
// - 4-up KPI grid (Foyda / Cheklar / Sotildi / Mijozlar)
// - The existing 3-tab structure (Daily / Monthly / Inventory) still drives
//   the detail sections — we only restyle the shell.

import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/reports/widgets/daily_report_tab.dart';
import 'package:market_system_client/features/reports/widgets/inventory_reporttab.dart';
import 'package:market_system_client/features/reports/widgets/monthly_report_tab.dart';
import 'package:market_system_client/features/reports/widgets/report_tabbar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/download_service.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/providers/auth_provider.dart';
import 'daily_sales_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late ReportService _reportsService;
  late DownloadService _downloadService;
  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  // Monthly tab's range. Independent of the hero band's period chips so a
  // chip tap never disturbs the tab the user set up.
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Hero band's own date window, driven by the period chips below the app
  // bar. Computed by _rangeFor from _heroPeriod.
  late DateTime _heroStart;
  late DateTime _heroEnd;

  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _periodReport;
  Map<String, dynamic>? _comprehensiveReport;
  Map<String, dynamic>? _heroReport;

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool _isDownloading = false;

  // Period chip selection for the hero. Maps to a window length we sum
  // across to render "JAMI" — Daily/Monthly tabs still drive their own
  // date pickers.
  _HeroPeriod _heroPeriod = _HeroPeriod.sevenDays;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final (heroStart, heroEnd) = _rangeFor(_heroPeriod);
    _heroStart = heroStart;
    _heroEnd = heroEnd;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _reportsService = ReportService(authProvider: authProvider);
    _downloadService = DownloadService.getInstance(authProvider.httpService);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Full reload — initial load, retry, and pull-to-refresh only. The per-input
  // handlers below reload ONLY the report that actually changed: a single
  // date/range/period tweak used to refetch and re-parse all four reports.
  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _reportsService.getDailyReport(_selectedDate),
        _reportsService.getPeriodReport(_startDate, _endDate),
        _reportsService.getComprehensiveReport(_selectedDate),
        _reportsService.getPeriodReport(_heroStart, _heroEnd),
      ]);
      if (!mounted) return;
      setState(() {
        _dailyReport = results[0] as Map<String, dynamic>?;
        _periodReport = results[1] as Map<String, dynamic>?;
        _comprehensiveReport = results[2] as Map<String, dynamic>?;
        _heroReport = results[3] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      _onLoadError(e);
    }
  }

  // Daily tab and Inventory tab share the SAME `_selectedDate` picker, so a
  // date change reloads both — but nothing else.
  Future<void> _loadDateReports() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _reportsService.getDailyReport(_selectedDate),
        _reportsService.getComprehensiveReport(_selectedDate),
      ]);
      if (!mounted) return;
      setState(() {
        _dailyReport = results[0] as Map<String, dynamic>?;
        _comprehensiveReport = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      _onLoadError(e);
    }
  }

  Future<void> _loadMonthly() async {
    setState(() => _isLoading = true);
    try {
      final r = await _reportsService.getPeriodReport(_startDate, _endDate);
      if (!mounted) return;
      setState(() {
        _periodReport = r as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      _onLoadError(e);
    }
  }

  Future<void> _loadHero() async {
    setState(() => _isLoading = true);
    try {
      final r = await _reportsService.getPeriodReport(_heroStart, _heroEnd);
      if (!mounted) return;
      setState(() {
        _heroReport = r as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      _onLoadError(e);
    }
  }

  void _onLoadError(Object e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = false);
    _showSnack('${l10n.error}: $e', isError: true);
  }

  /// Date window for a hero period. The end is always "now"; the start is
  /// midnight, N days back (today → midnight today, year → Jan 1).
  (DateTime, DateTime) _rangeFor(_HeroPeriod p) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (p) {
      case _HeroPeriod.today:
        return (todayStart, now);
      case _HeroPeriod.sevenDays:
        return (todayStart.subtract(const Duration(days: 6)), now);
      case _HeroPeriod.thirtyDays:
        return (todayStart.subtract(const Duration(days: 29)), now);
      case _HeroPeriod.year:
        return (DateTime(now.year, 1, 1), now);
    }
  }

  /// A hero period chip was tapped — recompute the window and reload so the
  /// band and KPIs reflect the picked period, not just the label.
  void _onHeroPeriodChanged(_HeroPeriod p) {
    if (p == _heroPeriod) return;
    final (start, end) = _rangeFor(p);
    setState(() {
      _heroPeriod = p;
      _heroStart = start;
      _heroEnd = end;
    });
    _loadHero();
  }

  Future<void> _loadDailySaleItems() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoadingDetails = true);
    try {
      final saleItems = await _reportsService.getDailySaleItems(_selectedDate);
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      // Snapshot AFTER the setState so the latest report value is captured;
      // if it's still null (e.g. the page opened before _loadReports finished)
      // we silently bail instead of crashing on `_dailyReport!`.
      final report = _dailyReport;
      if (mounted && report != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailySalesDetailsScreen(
              date: _selectedDate,
              dailyReport: report,
              saleItems: saleItems,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingDetails = false);
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    }
  }

  Future<void> _downloadExcelReport() async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    // Tab-aware export: on the Ombor (warehouse) tab the download button
    // exports the current inventory — all products with stock/valuation —
    // instead of the daily comprehensive report. Index 2 == InventoryReportTab.
    final isInventoryTab = _tabController.index == 2;

    setState(() => _isDownloading = true);
    try {
      if (isInventoryTab) {
        await _downloadService.downloadInventoryReport(
          date: _selectedDate,
          lang: lang,
        );
      } else {
        await _downloadService.downloadComprehensiveReport(
          date: _selectedDate,
          lang: lang,
        );
      }
      if (mounted) {
        _showSnack(l10n.reportDownloadSuccess, isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  // Hero band figures — all read from _heroReport, the period report for the
  // window the period chips selected (see _rangeFor). DailyReportDto and
  // PeriodReportDto share these keys, so no key fallbacks are needed.

  /// num-or-null → double, defaulting to 0.
  double _num(dynamic v) => v is num ? v.toDouble() : 0;

  double get _heroTurnover => _num(_heroReport?['totalSales']);

  double get _heroProfit => _num(_heroReport?['profit']);

  int get _heroReceipts => _num(_heroReport?['totalTransactions']).toInt();

  double get _heroPaid => _num(_heroReport?['totalPaidSales']);

  double get _heroDebt => _num(_heroReport?['totalDebtSales']);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canViewCostPrice = authProvider.can(Permissions.dataCostPrice);
    // Excel eksport ruxsati bo'lmasa (backend 403 qaytaradi), yuklab olish
    // tugmasini umuman ko'rsatmaymiz — foydalanuvchi mavjud bo'lmagan amalni
    // bosib xato olmasin.
    final canExport = authProvider.can(Permissions.reportsExport);

    return NetworkWrapper(
      onRetry: _loadReports,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(
          title: l10n.reports,
          extraActions: [
            // Faqat Excel eksport ruxsati bor foydalanuvchiga ko'rsatamiz.
            if (canExport)
              _isDownloading
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.brand,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download_rounded),
                      tooltip: l10n.downloadExcel,
                      onPressed: _downloadExcelReport,
                    ),
          ],

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: ReportTabBar(controller: _tabController),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: context.colors.brand),
              )
            : RefreshIndicator(
                color: context.colors.brand,
                onRefresh: _loadReports,
                child: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PeriodChips(
                              selected: _heroPeriod,
                              onChanged: _onHeroPeriodChanged,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ReportsHero(
                              period: _heroPeriod,
                              turnover: _heroTurnover,
                              currency: l10n.currencySom,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _KpiGrid(
                              profit: _heroProfit,
                              receipts: _heroReceipts,
                              paid: _heroPaid,
                              debt: _heroDebt,
                              l10n: l10n,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      DailyReportTab(
                        report: _dailyReport,
                        selectedDate: _selectedDate,
                        isLoadingDetails: _isLoadingDetails,
                        onDateChanged: (d) {
                          setState(() => _selectedDate = d);
                          _loadDateReports();
                        },
                        onViewDetails: _loadDailySaleItems,
                      ),
                      MonthlyReportTab(
                        report: _periodReport,
                        startDate: _startDate,
                        endDate: _endDate,
                        onRangeChanged: (start, end) {
                          setState(() {
                            _startDate = start;
                            _endDate = end;
                          });
                          _loadMonthly();
                        },
                      ),
                      InventoryReportTab(
                        report: _comprehensiveReport,
                        selectedDate: _selectedDate,
                        onDateChanged: (d) {
                          setState(() => _selectedDate = d);
                          _loadDateReports();
                        },
                        canViewCostPrice: canViewCostPrice,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Period segmented control above the hero. Demo's `.rpt-period`.
enum _HeroPeriod { today, sevenDays, thirtyDays, year }

class _PeriodChips extends StatelessWidget {
  final _HeroPeriod selected;
  final ValueChanged<_HeroPeriod> onChanged;

  const _PeriodChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(String, _HeroPeriod)>[
      (l10n.today, _HeroPeriod.today),
      (l10n.period7Days, _HeroPeriod.sevenDays),
      (l10n.period30Days, _HeroPeriod.thirtyDays),
      (l10n.periodYear, _HeroPeriod.year),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _PeriodChip(
                  label: e.$1,
                  active: e.$2 == selected,
                  onTap: () => onChanged(e.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: active ? context.colors.brand : context.colors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? context.colors.brand : context.colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active
                ? context.colors.onBrand
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Dark navy "JAMI" gradient hero shown above the report tabs.
/// Demo's `.rpt-hero` block in `id="page-rpt-hub"`.
class _ReportsHero extends StatelessWidget {
  final _HeroPeriod period;
  final double turnover;
  final String currency;

  const _ReportsHero({
    required this.period,
    required this.turnover,
    required this.currency,
  });

  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final jami = l10n.totalSum.toUpperCase();
    switch (period) {
      case _HeroPeriod.today:
        return '${l10n.today.toUpperCase()} · $jami';
      case _HeroPeriod.sevenDays:
        return '${l10n.period7Days.toUpperCase()} · $jami';
      case _HeroPeriod.thirtyDays:
        return '${l10n.period30Days.toUpperCase()} · $jami';
      case _HeroPeriod.year:
        return '${l10n.periodYear.toUpperCase()} · $jami';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBg, AppColors.darkSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBg.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label(context),
            style: AppTextStyles.labelSmall().copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Text(
            '${NumberFormatter.format(turnover)} $currency',
            style: AppTextStyles.displayLarge().copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 4-up KPI grid (Foyda / Cheklar / Sotildi / Mijozlar).
/// Demo's `.kpi-grid` block inside `id="page-rpt-hub"`.
class _KpiGrid extends StatelessWidget {
  final double profit;
  final int receipts;
  final double paid;
  final double debt;
  final AppLocalizations l10n;

  const _KpiGrid({
    required this.profit,
    required this.receipts,
    required this.paid,
    required this.debt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Kartochkalar VERTIKAL (balandan pastga) — har biri to'liq kenglikda,
    // shunda to'liq summa ("87 000 000") kesilmasdan sig'adi. 4 tadan bir
    // qatorli tor variantda katta sonlar kesilib qolardi.
    return Column(
      children: [
        _KpiTile(
          icon: Icons.payments_rounded,
          iconBg: AppColors.successLight,
          iconColor: AppColors.success,
          label: l10n.netProfit,
          value: NumberFormatter.format(profit),
        ),
        const SizedBox(height: AppSpacing.md),
        _KpiTile(
          icon: Icons.receipt_long_rounded,
          iconBg: context.colors.brandLight,
          iconColor: context.colors.brand,
          label: l10n.saleCount,
          value: receipts.toString(),
        ),
        const SizedBox(height: AppSpacing.md),
        _KpiTile(
          icon: Icons.check_circle_outline_rounded,
          iconBg: AppColors.successLight,
          iconColor: AppColors.success,
          label: l10n.paid,
          value: NumberFormatter.format(paid),
        ),
        const SizedBox(height: AppSpacing.md),
        _KpiTile(
          icon: Icons.warning_amber_rounded,
          iconBg: AppColors.dangerLight,
          iconColor: AppColors.danger,
          label: l10n.onDebt,
          value: NumberFormatter.format(debt),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _KpiTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // To'liq kenglikdagi gorizontal karta: ikonka chapda, label + to'liq son
    // o'ngda. Endi qiymatga butun qator eni tegadi — "87 000 000" bemalol
    // sig'adi. FittedBox faqat juda katta son (mlrd) uchun himoya sifatida.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTextStyles.titleMedium().copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.colors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
