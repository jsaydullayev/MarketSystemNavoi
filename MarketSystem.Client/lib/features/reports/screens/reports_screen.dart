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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _periodReport;
  Map<String, dynamic>? _comprehensiveReport;

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

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _reportsService.getDailyReport(_selectedDate),
        _reportsService.getPeriodReport(_startDate, _endDate),
        _reportsService.getComprehensiveReport(_selectedDate),
      ]);
      if (!mounted) return;
      setState(() {
        _dailyReport = results[0] as Map<String, dynamic>?;
        _periodReport = results[1] as Map<String, dynamic>?;
        _comprehensiveReport = results[2] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isLoading = false);
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    }
  }

  Future<void> _loadDailySaleItems() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoadingDetails = true);
    try {
      final saleItems = await _reportsService.getDailySaleItems(_selectedDate);
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailySalesDetailsScreen(
              date: _selectedDate,
              dailyReport: _dailyReport!,
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

    setState(() => _isDownloading = true);
    try {
      await _downloadService.downloadComprehensiveReport(date: _selectedDate);
      if (mounted) {
        _showSnack(l10n.reportDownloadSuccess, isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _exportToExcel(String type) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      switch (type) {
        case 'daily':
          await _reportsService.exportDailyReportToExcel(_selectedDate);
          break;
        case 'monthly':
          await _reportsService.exportPeriodReportToExcel(_startDate, _endDate);
          break;
        case 'inventory':
          await _reportsService.exportInventoryReportToExcel(_selectedDate);
          break;
      }
      if (mounted) _showSnack('${l10n.reportDownloaded}!', isError: false);
    } catch (e) {
      if (mounted) _showSnack('${l10n.downloadError}!: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      margin: const EdgeInsets.all(AppSpacing.xl),
    ));
  }

  /// Aggregate the period report into a "turnover" total for the hero band.
  double get _heroTurnover {
    final source = _periodReport ?? _dailyReport;
    if (source == null) return 0;
    final v = source['totalSales'] ?? source['totalAmount'] ?? 0;
    return v is num ? v.toDouble() : 0;
  }

  double get _heroProfit {
    final source = _periodReport ?? _dailyReport;
    if (source == null) return 0;
    final v = source['profit'] ?? source['totalProfit'] ?? 0;
    return v is num ? v.toDouble() : 0;
  }

  int get _heroReceipts {
    final source = _periodReport ?? _dailyReport;
    if (source == null) return 0;
    final v = source['totalTransactions'] ??
        source['receiptCount'] ??
        source['salesCount'] ??
        0;
    return v is num ? v.toInt() : 0;
  }

  int get _heroSold {
    final source = _periodReport ?? _comprehensiveReport;
    if (source == null) return 0;
    final v = source['totalSoldItems'] ??
        source['itemsSold'] ??
        source['totalQuantity'] ??
        0;
    return v is num ? v.toInt() : 0;
  }

  int get _heroCustomers {
    final source = _periodReport ?? _dailyReport;
    if (source == null) return 0;
    final v = source['totalCustomers'] ??
        source['customersCount'] ??
        source['uniqueCustomers'] ??
        0;
    return v is num ? v.toInt() : 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canViewCostPrice = authProvider.user?['role'] != 'Seller';

    return NetworkWrapper(
      onRetry: _loadReports,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: CommonAppBar(
          title: l10n.reports,
          extraActions: [
            _isDownloading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
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
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              )
            : RefreshIndicator(
                color: AppColors.brand,
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
                              onChanged: (p) =>
                                  setState(() => _heroPeriod = p),
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
                              sold: _heroSold,
                              customers: _heroCustomers,
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
                          _loadReports();
                        },
                        onViewDetails: _loadDailySaleItems,
                        onExport: () => _exportToExcel('daily'),
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
                          _loadReports();
                        },
                        onExport: () => _exportToExcel('monthly'),
                      ),
                      InventoryReportTab(
                        report: _comprehensiveReport,
                        selectedDate: _selectedDate,
                        onDateChanged: (d) {
                          setState(() => _selectedDate = d);
                          _loadReports();
                        },
                        onExport: () => _exportToExcel('inventory'),
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
      ('7 kun', _HeroPeriod.sevenDays),
      ('30 kun', _HeroPeriod.thirtyDays),
      ('Yil', _HeroPeriod.year),
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
          color: active ? AppColors.brand : AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? AppColors.brand : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
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
        return '7-KUNLIK · $jami';
      case _HeroPeriod.thirtyDays:
        return '30-KUNLIK · $jami';
      case _HeroPeriod.year:
        return 'YILLIK · $jami';
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
  final int sold;
  final int customers;
  final AppLocalizations l10n;

  const _KpiGrid({
    required this.profit,
    required this.receipts,
    required this.sold,
    required this.customers,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            icon: Icons.payments_rounded,
            iconBg: AppColors.successLight,
            iconColor: AppColors.success,
            label: l10n.netProfit,
            value: NumberFormatter.format(profit),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiTile(
            icon: Icons.receipt_long_rounded,
            iconBg: AppColors.brandLight,
            iconColor: AppColors.brand,
            label: l10n.saleCount,
            value: receipts.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiTile(
            icon: Icons.inventory_2_outlined,
            iconBg: AppColors.warningLight,
            iconColor: AppColors.warning,
            label: l10n.quantity,
            value: sold.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiTile(
            icon: Icons.people_alt_outlined,
            iconBg: AppColors.dangerLight,
            iconColor: AppColors.danger,
            label: l10n.customers,
            value: customers.toString(),
          ),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption().copyWith(
              fontSize: 9,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge().copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
