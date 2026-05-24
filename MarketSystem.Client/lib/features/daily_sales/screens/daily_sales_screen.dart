import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/file_helper.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/daily_sales/widgets/daily_summary_card.dart';
import 'package:market_system_client/features/daily_sales/widgets/hourly_chart.dart';
import 'package:market_system_client/features/daily_sales/widgets/sale_detail_sheet.dart';
import 'package:market_system_client/features/daily_sales/widgets/sale_list_row.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/sales_service.dart';
import '../../../data/models/profit_model.dart';
import '../../../l10n/app_localizations.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  DateTime _selectedDate = DateTime.now();
  DailySalesListModel? _dailySales;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;
  DailySaleFilter _filter = DailySaleFilter.all;

  /// Apply the active filter to the loaded sales list. Kept inline (no helper
  /// service) — the rule is tiny and the user expects this to react instantly
  /// without refetching from the API.
  List<DailySalesListItemModel> get _visibleSales {
    // Snapshot the field so Dart can promote it to non-null below; field
    // accesses don't survive the early-return guard otherwise.
    final dailySales = _dailySales;
    if (dailySales == null) return const [];
    switch (_filter) {
      case DailySaleFilter.all:
        return dailySales.sales;
      case DailySaleFilter.paid:
        // "Paid" in the UI bucket means any fully-paid sale, including a
        // debt-on-record that was later closed by the customer.
        return dailySales.sales.where((s) {
          final st = s.status.toLowerCase();
          return st == 'paid' || st == 'closed';
        }).toList();
      case DailySaleFilter.debt:
        return dailySales.sales
            .where((s) => s.status.toLowerCase() == 'debt')
            .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDailySales();
  }

  Future<void> _loadDailySales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportService(authProvider: authProvider);
      final sales = await reportService.getDailySalesList(_selectedDate);

      setState(() {
        _dailySales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.colors.brand),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDailySales();
    }
  }

  // ───────────────────────── Export ─────────────────────────

  Future<void> _showExportSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.colors.border),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eksport qilish',
                style: AppTextStyles.titleMedium().copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM, yyyy').format(_selectedDate),
                style: AppTextStyles.bodySmall(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ExportOption(
                icon: Icons.picture_as_pdf_outlined,
                color: AppColors.danger,
                label: 'PDF formatda',
                description: 'Sotuvlar ro\'yxati + jami',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _exportPdf();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ExportOption(
                icon: Icons.table_chart_outlined,
                color: AppColors.success,
                label: 'Excel formatda',
                description: 'To\'liq hisobot (sotuvlar + mahsulotlar)',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _exportExcel();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final lang = Localizations.localeOf(context).languageCode;
      // PDF endpoint accepts a date range; collapse it to a single day.
      final bytes = await salesService.downloadSalesPdf(
        startDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        endDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          23,
          59,
          59,
        ),
        lang: lang,
      );
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        _toast('PDF yuklashda xatolik', success: false);
        return;
      }
      final name =
          'Kunlik_savdo_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.pdf';
      final ok = await FileHelper.saveAndOpenPdf(bytes, name);
      if (!mounted) return;
      _toast(
        ok
            ? (kIsWeb ? 'PDF fayli yuklanmoqda...' : 'PDF saqlandi va ochildi')
            : 'PDF saqlashda xatolik',
        success: ok,
      );
    } catch (e) {
      if (mounted) _toast('Xatolik: $e', success: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportService(authProvider: authProvider);
      final bytes = await reportService.downloadDailyExcel(_selectedDate);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        _toast('Excel yuklashda xatolik', success: false);
        return;
      }
      final name =
          'Kunlik_savdo_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.xlsx';
      final ok = await FileHelper.saveAndOpenExcel(bytes, name);
      if (!mounted) return;
      _toast(
        ok
            ? (kIsWeb
                  ? 'Excel fayli yuklanmoqda...'
                  : 'Excel saqlandi va ochildi')
            : 'Excel saqlashda xatolik',
        success: ok,
      );
    } catch (e) {
      if (mounted) _toast('Xatolik: $e', success: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _toast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _showSaleDetails(DailySalesListItemModel sale) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canSeeProfit = authProvider.can(Permissions.dataProfit);
    final salesService = SalesService(authProvider: authProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
          ),
        ),
      ),
    );

    try {
      final saleDetails = await salesService.getSaleById(sale.id);
      if (!mounted) return;
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SaleDetailSheet(
          sale: sale,
          saleDetails: saleDetails,
          isOwner: canSeeProfit,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadDailySales,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(
          title: l10n.dailySales,
          extraActions: [
            // Export — disabled while a download is in flight or before data
            // arrives. We show a spinner in-place rather than a toast so the
            // user knows their tap registered.
            IconButton(
              tooltip: 'Eksport',
              icon: _isExporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colors.brand,
                        ),
                      ),
                    )
                  : Icon(Icons.ios_share_rounded, color: context.colors.brand),
              onPressed: (_isExporting || _dailySales == null)
                  ? null
                  : _showExportSheet,
            ),
            IconButton(
              tooltip: 'Kalendar',
              icon: Icon(
                Icons.calendar_month_rounded,
                color: context.colors.brand,
              ),
              onPressed: _selectDate,
            ),
          ],
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildDateBadge(context),
                Expanded(child: _buildBody(context, l10n)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.borderSoft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 18, color: context.colors.brand),
          const SizedBox(width: AppSpacing.md),
          Text(
            DateFormat('dd MMMM, yyyy').format(_selectedDate),
            style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
        ),
      );
    }

    // Snapshot the nullable state fields into locals so every later branch
    // is type-checked as non-null without `!` round-trips.
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(),
            ),
            TextButton(
              onPressed: _loadDailySales,
              child: Text(
                l10n.loading,
                style: AppTextStyles.labelLarge().copyWith(
                  color: context.colors.brand,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dailySales = _dailySales;
    if (dailySales == null || dailySales.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: context.colors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.noData,
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final visible = _visibleSales;
    final hasFilter = _filter != DailySaleFilter.all;

    return RefreshIndicator(
      color: context.colors.brand,
      onRefresh: _loadDailySales,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          DailySummaryCard(
            data: dailySales,
            selectedFilter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.lg),
          HourlyChart(sales: dailySales.sales),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    l10n.sales,
                    style: AppTextStyles.labelLarge().copyWith(fontSize: 15),
                  ),
                  if (hasFilter) ...[
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _filter = DailySaleFilter.all),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _filterColor(
                            context,
                            _filter,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _filterLabel(_filter, l10n),
                              style: AppTextStyles.caption().copyWith(
                                color: _filterColor(context, _filter),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: _filterColor(context, _filter),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${visible.length} ${l10n.piece}',
                  style: AppTextStyles.caption().copyWith(
                    color: context.colors.brandDark,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl3),
              child: Center(
                child: Text(l10n.noData, style: AppTextStyles.bodySmall()),
              ),
            )
          else
            ...visible.map(
              (sale) =>
                  SaleListRow(sale: sale, onTap: () => _showSaleDetails(sale)),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Color _filterColor(BuildContext context, DailySaleFilter f) {
    switch (f) {
      case DailySaleFilter.paid:
        return AppColors.success;
      case DailySaleFilter.debt:
        return AppColors.warning;
      case DailySaleFilter.all:
        return context.colors.textMuted;
    }
  }

  String _filterLabel(DailySaleFilter f, AppLocalizations l10n) {
    switch (f) {
      case DailySaleFilter.paid:
        return l10n.paid;
      case DailySaleFilter.debt:
        return l10n.debt;
      case DailySaleFilter.all:
        return l10n.totalSale;
    }
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
