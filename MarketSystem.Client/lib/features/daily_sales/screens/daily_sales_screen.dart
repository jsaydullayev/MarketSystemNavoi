import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/utils/file_helper.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/features/daily_sales/widgets/daily_summary_card.dart';
import 'package:market_system_client/features/daily_sales/widgets/hourly_chart.dart';
import 'package:market_system_client/features/daily_sales/widgets/sale_detail_sheet.dart';
import 'package:market_system_client/features/daily_sales/widgets/sale_list_row.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
    if (_dailySales == null) return const [];
    switch (_filter) {
      case DailySaleFilter.all:
        return _dailySales!.sales;
      case DailySaleFilter.paid:
        // "Paid" in the UI bucket means any fully-paid sale, including a
        // debt-on-record that was later closed by the customer.
        return _dailySales!.sales.where((s) {
          final st = s.status.toLowerCase();
          return st == 'paid' || st == 'closed';
        }).toList();
      case DailySaleFilter.debt:
        return _dailySales!.sales
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

      if (!mounted) return;
      setState(() {
        _dailySales = sales;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eksport qilish',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM, yyyy').format(_selectedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              _ExportOption(
                icon: Icons.picture_as_pdf_outlined,
                color: const Color(0xFFEF4444),
                label: 'PDF formatda',
                description: 'Sotuvlar ro\'yxati + jami',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _exportPdf();
                },
              ),
              const SizedBox(height: 10),
              _ExportOption(
                icon: Icons.table_chart_outlined,
                color: const Color(0xFF10B981),
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
      // PDF endpoint accepts a date range; collapse it to a single day.
      final bytes = await salesService.downloadSalesPdf(
        startDate: DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day),
        endDate: DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, 23, 59, 59),
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
            ? (kIsWeb ? 'Excel fayli yuklanmoqda...' : 'Excel saqlandi va ochildi')
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
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _showSaleDetails(DailySalesListItemModel sale) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?['role'] == 'Owner';
    final salesService = SalesService(authProvider: authProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
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
          isOwner: isOwner,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return NetworkWrapper(
      onRetry: _loadDailySales,
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
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
                        color: theme.primaryColor,
                      ),
                    )
                  : Icon(Icons.ios_share_rounded, color: theme.primaryColor),
              onPressed: (_isExporting || _dailySales == null)
                  ? null
                  : _showExportSheet,
            ),
            IconButton(
              tooltip: 'Kalendar',
              icon:
                  Icon(Icons.calendar_month_rounded, color: theme.primaryColor),
              onPressed: _selectDate,
            ),
          ],
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildDateBadge(theme, isDark),
                Expanded(child: _buildBody(l10n, theme, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd MMMM, yyyy').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme, bool isDark) {
    final primary = Theme.of(context).primaryColor;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadDailySales, child: Text(l10n.loading)),
          ],
        ),
      );
    }

    if (_dailySales == null || _dailySales!.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: theme.disabledColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(l10n.noData, style: TextStyle(color: theme.disabledColor)),
          ],
        ),
      );
    }

    final visible = _visibleSales;
    final hasFilter = _filter != DailySaleFilter.all;

    return RefreshIndicator(
      onRefresh: _loadDailySales,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DailySummaryCard(
            data: _dailySales!,
            selectedFilter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 14),
          HourlyChart(sales: _dailySales!.sales),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    l10n.sales,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  if (hasFilter) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _filter = DailySaleFilter.all),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _filterColor(_filter).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _filterLabel(_filter, l10n),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _filterColor(_filter),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close_rounded,
                                size: 12, color: _filterColor(_filter)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${visible.length} ${l10n.piece}',
                  style: TextStyle(
                    color: isDark ? Colors.white : primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.noData,
                  style: TextStyle(
                    color: theme.disabledColor,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...visible.map(
              (sale) => SaleListRow(
                sale: sale,
                onTap: () => _showSaleDetails(sale),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Color _filterColor(DailySaleFilter f) {
    switch (f) {
      case DailySaleFilter.paid:
        return const Color(0xFF4ADE80);
      case DailySaleFilter.debt:
        return const Color(0xFFFCD34D);
      case DailySaleFilter.all:
        return Colors.grey;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.grey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
