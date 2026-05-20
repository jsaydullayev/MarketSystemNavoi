import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/features/reports/widgets/date_picker_row.dart';
import 'package:market_system_client/features/reports/widgets/empty_report.dart';
import 'package:market_system_client/features/reports/widgets/export_button.dart';
import 'package:market_system_client/features/reports/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/reports/widgets/section_title.dart';
import 'package:market_system_client/features/reports/widgets/stat_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Daily tab inside the Reports screen.
///
/// Layout matches the demo's `id="page-rpt-hub"` cards: a date selector,
/// then 2x2 KPI grid (sales/profit then paid/debt), then a payment-method
/// breakdown when present. The Excel export action sits at the bottom.
class DailyReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final DateTime selectedDate;
  final bool isLoadingDetails;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onViewDetails;
  final VoidCallback onExport;

  const DailyReportTab({
    super.key,
    required this.report,
    required this.selectedDate,
    required this.isLoadingDetails,
    required this.onDateChanged,
    required this.onViewDetails,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (report == null) {
      return const EmptyReport();
    }

    final totalSales = (report!['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalTx = (report!['totalTransactions'] as num?)?.toInt() ?? 0;
    final totalPaid = (report!['totalPaidSales'] as num?)?.toDouble() ?? 0.0;
    final totalDebt = (report!['totalDebtSales'] as num?)?.toDouble() ?? 0.0;
    final profit = report!['profit'] is num
        ? (report!['profit'] as num).toDouble()
        : null;
    final payments = report!['paymentBreakdown'] is List
        ? report!['paymentBreakdown'] as List
        : [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl4),
      children: [
        DatePickerRow(selectedDate: selectedDate, onChanged: onDateChanged),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.dailySales,
                value:
                    '${NumberFormatter.formatDecimal(totalSales)} ${l10n.currencySom}',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
                subtitle: l10n.salesCount(totalTx),
                isClickable: true,
                isLoading: isLoadingDetails,
                onTap: onViewDetails,
              ),
            ),
            if (profit != null) ...[
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: StatCard(
                  title: l10n.netProfit,
                  value:
                      '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: context.colors.brand,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.paid,
                value:
                    '${NumberFormatter.formatDecimal(totalPaid)} ${l10n.currencySom}',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: StatCard(
                title: l10n.onDebt,
                value:
                    '${NumberFormatter.formatDecimal(totalDebt)} ${l10n.currencySom}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        if (payments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl2),
          SectionTitle(title: l10n.byPaymentType),
          const SizedBox(height: AppSpacing.md + 2),
          ...payments.map((p) {
            if (p is! Map<String, dynamic>) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ReportPaymentBreakdownCard(
                paymentType: p['paymentType']?.toString() ?? '',
                amount: (p['amount'] as num?)?.toDouble() ?? 0,
                count: (p['count'] as num?)?.toInt() ?? 0,
                totalSales: totalSales,
              ),
            );
          }),
        ],
        const SizedBox(height: AppSpacing.xl2),
        ExportButton(onTap: onExport),
      ],
    );
  }
}
