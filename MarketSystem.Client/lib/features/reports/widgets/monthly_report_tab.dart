import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/features/reports/widgets/date_range_picker.dart';
import 'package:market_system_client/features/reports/widgets/empty_report.dart';
import 'package:market_system_client/features/reports/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/reports/widgets/section_title.dart';
import 'package:market_system_client/features/reports/widgets/stat_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Monthly (date-range) tab inside the Reports screen.
///
/// Layout matches the demo's profit/period view: range picker, then a
/// stacked column of KPI cards (aylanma, soni, paid, debt, average,
/// profit), then payment-method breakdown when present.
class MonthlyReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onRangeChanged;

  const MonthlyReportTab({
    super.key,
    required this.report,
    required this.startDate,
    required this.endDate,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (report == null) return const EmptyReport();
    final l10n = AppLocalizations.of(context)!;
    final totalSales = (report!['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalTx = (report!['totalTransactions'] as num?)?.toInt() ?? 0;
    final totalPaid = (report!['totalPaidSales'] as num?)?.toDouble() ?? 0.0;
    final totalDebt = (report!['totalDebtSales'] as num?)?.toDouble() ?? 0.0;
    final avgSale = (report!['averageSale'] as num?)?.toDouble() ?? 0.0;
    final profit = report!['profit'] is num
        ? (report!['profit'] as num).toDouble()
        : null;
    final payments = report!['paymentBreakdown'] is List
        ? report!['paymentBreakdown'] as List
        : [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl4,
      ),
      children: [
        DateRangeRow(
          startDate: startDate,
          endDate: endDate,
          onChanged: onRangeChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.totalSale,
                value:
                    '${NumberFormatter.formatDecimal(totalSales)} ${l10n.currencySom}',
                icon: Icons.attach_money_rounded,
                color: context.colors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: StatCard(
                title: l10n.saleCount,
                value: '$totalTx ${l10n.piece}',
                icon: Icons.shopping_cart_outlined,
                color: AppColors.warning,
              ),
            ),
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
        const SizedBox(height: AppSpacing.lg),
        StatCard(
          title: l10n.averageSale,
          value:
              '${NumberFormatter.formatDecimal(avgSale)} ${l10n.currencySom}',
          icon: Icons.calculate_outlined,
          color: AppColors.accentViolet,
          subtitle: l10n.averageTransactionValue,
        ),
        if (profit != null) ...[
          const SizedBox(height: AppSpacing.lg),
          StatCard(
            title: l10n.netProfit,
            value:
                '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.success,
          ),
        ],
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
      ],
    );
  }
}
