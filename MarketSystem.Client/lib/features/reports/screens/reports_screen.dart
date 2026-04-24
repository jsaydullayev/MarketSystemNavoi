import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
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
      setState(() {
        _dailyReport = results[0] as Map<String, dynamic>?;
        _periodReport = results[1] as Map<String, dynamic>?;
        _comprehensiveReport = results[2] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
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
          // Kunlik hisobot: kunlik hisobot + sotuvlar ro'yxati + mahsulotlar bo'yicha
          await _reportsService.exportDailyReportToExcel(_selectedDate);
          break;
        case 'monthly':
          // Oylik ma'lumotlar va barcha tegishli ma'lumotlar
          await _reportsService.exportPeriodReportToExcel(_startDate, _endDate);
          break;
        case 'inventory':
          // Omborga tegishli barcha ma'lumotlar
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
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canViewCostPrice = authProvider.user?['role'] != 'Seller';

    return NetworkWrapper(
      onRetry: _loadReports,
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
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
                          strokeWidth: 2, color: Colors.white),
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
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadReports,
                child: TabBarView(
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
    );
  }
}
