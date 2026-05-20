import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sale_entity.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/states/sales_state.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedStatus = 'all';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    context.read<SalesBloc>().add(const GetSalesEvent());
  }

  List<SaleEntity> _filterSales(List<SaleEntity> sales) {
    List<SaleEntity> filtered;

    if (_selectedStatus == 'all') {
      filtered = List.from(sales);
    } else {
      filtered = sales
          .where((s) => s.getStatusText().toLowerCase() == _selectedStatus)
          .toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppColors.darkPrimaryLight; // blue from token palette
      case 'paid':
        return AppColors.success;
      case 'closed':
        return AppColors.darkPrimary; // indigo-ish from token palette
      case 'debt':
        return AppColors.danger;
      case 'cancelled':
        return context.colors.textMuted;
      default:
        return context.colors.brand;
    }
  }

  String _getStatusName(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'draft':
        // User-facing label = "Davom etayotgan" / "В процессе".
        // Backend keeps `Draft` for the enum.
        return l10n.ongoing;
      case 'paid':
        return l10n.paid;
      case 'closed':
        return l10n.closed;
      case 'debt':
        return l10n.debt;
      default:
        return status;
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final bytes = await salesService.downloadSalesExcel();

      if (bytes != null && bytes.isNotEmpty) {
        final success = await core_file_helper.FileHelper.saveAndOpenExcel(
            bytes, 'Sotuvlar.xlsx');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                  kIsWeb && success
                      ? 'Excel fayli yuklanmoqda...'
                      : (success ? 'Excel saqlandi va ochildi' : 'Error'),
                ),
                backgroundColor:
                    success ? AppColors.success : AppColors.danger),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final bytes = await salesService.downloadSalesPdf();

      if (bytes != null && bytes.isNotEmpty) {
        final success = await core_file_helper.FileHelper.saveAndOpenPdf(
            bytes, 'Sotuvlar.pdf');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                  kIsWeb && success
                      ? 'PDF fayli yuklanmoqda...'
                      : (success
                          ? 'PDF saqlandi va ochildi'
                          : 'PDF saqlashda xatolik'),
                ),
                backgroundColor:
                    success ? AppColors.success : AppColors.danger),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF faylini yuklab olishda xatolik yuz berdi'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger));
        }
      },
      child: NetworkWrapper(
        onRetry: _loadSales,
        child: Scaffold(
          backgroundColor: context.colors.bg,
          appBar: CommonAppBar(
            title: l10n.sales,
            onRefresh: _loadSales,
            extraActions: _isExporting
                ? [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.brand),
                          ),
                        ),
                      ),
                    ),
                  ]
                : [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.file_download_outlined,
                        color: context.colors.text,
                      ),
                      tooltip: 'Export',
                      onSelected: (value) {
                        if (value == 'excel') {
                          _exportExcel();
                        } else if (value == 'pdf') {
                          _exportPdf();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              const Icon(Icons.table_view,
                                  size: 20, color: AppColors.success),
                              const SizedBox(width: AppSpacing.lg),
                              Text('Excel export',
                                  style: AppTextStyles.bodyMedium()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf,
                                  size: 20, color: AppColors.danger),
                              const SizedBox(width: AppSpacing.lg),
                              Text('PDF export',
                                  style: AppTextStyles.bodyMedium()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: BlocBuilder<SalesBloc, SalesState>(
                builder: (context, state) {
                  if (state is SalesLoading) {
                    return Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.brand)));
                  }

                  if (state is SalesLoaded) {
                    final filteredSales = _filterSales(state.sales);
                    return Column(
                      children: [
                        _buildHeroSummary(context, state.sales, l10n),
                        _buildStatusChips(context, state.sales, l10n),
                        Expanded(
                          child: RefreshIndicator(
                            color: context.colors.brand,
                            onRefresh: () async => _loadSales(),
                            child: filteredSales.isEmpty
                                ? _buildEmptyState(context, l10n)
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xl),
                                    itemCount: filteredSales.length,
                                    itemBuilder: (context, index) =>
                                        _buildSaleItem(context,
                                            filteredSales[index], l10n),
                                  ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                          value: context.read<SalesBloc>(),
                          child: const NewSaleScreen())));
              if (result == true && mounted) _loadSales();
            },
            backgroundColor: context.colors.brand,
            icon: const Icon(Icons.add_shopping_cart_rounded,
                color: Colors.white),
            label: Text(l10n.newSale,
                style: AppTextStyles.labelLarge()
                    .copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  /// Orange gradient hero card — matches demo's "BUGUN JAMI" tile.
  Widget _buildHeroSummary(
      BuildContext context, List<SaleEntity> sales, AppLocalizations l10n) {
    final today = DateTime.now();
    final todaySales = sales.where((s) =>
        s.createdAt.year == today.year &&
        s.createdAt.month == today.month &&
        s.createdAt.day == today.day);

    final totalToday =
        todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final countToday = todaySales.length;
    final debtCount =
        todaySales.where((s) => s.getStatusText().toLowerCase() == 'debt').length;
    final ongoing = todaySales
        .where((s) => s.getStatusText().toLowerCase() == 'draft')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.brand, context.colors.brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: context.colors.brand.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BUGUN JAMI',
                  style: AppTextStyles.caption()
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                Text(
                  DateFormat('dd MMM').format(today),
                  style: AppTextStyles.labelSmall()
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${NumberFormatter.format(totalToday)} UZS',
                style: AppTextStyles.displayMedium()
                    .copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _heroStat('$countToday', 'chek'),
                _heroDivider(),
                _heroStat('$ongoing', l10n.ongoing.toLowerCase()),
                _heroDivider(),
                _heroStat('$debtCount', l10n.debt.toLowerCase()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.titleMedium()
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSmall()
                  .copyWith(color: Colors.white.withValues(alpha: 0.85)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.25),
      );

  Widget _buildStatusChips(
      BuildContext context, List<SaleEntity> sales, AppLocalizations l10n) {
    final List<Map<String, dynamic>> statuses = [
      {'id': 'all', 'label': l10n.all},
      // Status is still 'Draft' on the backend; only the user-facing
      // label changes — "Davom etayotgan" / "В процессе" reads more
      // accurately for a sale the seller is mid-way through.
      {'id': 'draft', 'label': l10n.ongoing},
      {'id': 'paid', 'label': l10n.paid},
      {'id': 'closed', 'label': l10n.closed},
      {'id': 'debt', 'label': l10n.debt},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final s = statuses[index];
          final bool isSelected = _selectedStatus == s['id'];
          final int count = s['id'] == 'all'
              ? sales.length
              : sales
                  .where(
                      (item) => item.getStatusText().toLowerCase() == s['id'])
                  .length;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = s['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.text
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.text
                        : context.colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s['label'] as String,
                      style: AppTextStyles.labelSmall().copyWith(
                        // Selected pill bg is `context.colors.text` (flips
                        // with the theme) — the label must be its inverse
                        // (`surface`), not a fixed white that disappears on
                        // the light dark-mode pill.
                        color: isSelected
                            ? context.colors.surface
                            : context.colors.text,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.surface.withValues(alpha: 0.18)
                            : context.colors.inputFill,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.caption().copyWith(
                          color: isSelected
                              ? context.colors.surface
                              : context.colors.textSecondary,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaleItem(
      BuildContext context, SaleEntity sale, AppLocalizations l10n) {
    final statusText = sale.getStatusText().toLowerCase();
    final statusColor = _getStatusColor(context, statusText);
    final dateStr = DateFormat('HH:mm').format(sale.createdAt);
    final dayStr = DateFormat('dd MMM').format(sale.createdAt);

    // Pick a payment icon by status: paid=cash, closed=card, debt=notebook,
    // draft=hourglass. Matches the demo's `.pay-ic.cash/.card/.debt` palette.
    // Colours come from the design tokens — no raw hex.
    final (IconData icon, Color tone) = switch (statusText) {
      'paid' => (Icons.payments_rounded, AppColors.success),
      'closed' => (Icons.credit_card_rounded, AppColors.darkPrimary),
      'debt' => (Icons.assignment_outlined, AppColors.warning),
      'draft' => (Icons.hourglass_bottom_rounded, AppColors.darkPrimaryLight),
      _ => (Icons.receipt_long_rounded, context.colors.textSecondary),
    };

    final isCancelled = statusText == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                        value: context.read<SalesBloc>(),
                        child: SaleDetailScreen(saleId: sale.id),
                      ))),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Opacity(
            opacity: isCancelled ? 0.65 : 1,
            // AppCard gives us the demo's 1px border + 14-radius + white
            // surface, matching `.sale-row` in design-demo/index.html.
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: tone, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sale.customerName ?? l10n.noCustomer,
                                style: AppTextStyles.labelLarge()
                                    .copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCancelled) ...[
                              const SizedBox(width: AppSpacing.md),
                              // "Qaytarildi" badge mirrors `.badge-refund`
                              // in the demo's refunded sale rows.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  l10n.returnAction.toUpperCase(),
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.danger,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              dateStr,
                              style: AppTextStyles.bodySmall(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$dayStr · ${sale.sellerName ?? ''}',
                                style: AppTextStyles.bodySmall().copyWith(
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              NumberFormatter.format(sale.totalAmount),
                              style: AppTextStyles.labelLarge().copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                // Refunded / cancelled rows: strike-through
                                // amount and recolour to danger, like
                                // `.sale-row.refunded .total` in the demo.
                                color: isCancelled
                                    ? AppColors.danger
                                    : context.colors.text,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                _getStatusName(sale.getStatusText(), l10n)
                                    .toUpperCase(),
                                style: AppTextStyles.caption().copyWith(
                                  color: statusColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64,
                  color:
                      context.colors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.noData,
                  style: AppTextStyles.bodyMedium()
                      .copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
