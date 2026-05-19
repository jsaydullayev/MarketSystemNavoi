import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/models/cash_register_model.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Today's sales summary card.
///
/// Demo reference: `.z-stats-grid` + the "TODAY" lines on the Z-report
/// (`id="page-staff-shift"`). Section title in uppercase, then a series of
/// labeled rows: sale count, total, paid, debt.
class TodaySalesCard extends StatelessWidget {
  final TodaySalesSummaryModel todaySales;

  const TodaySalesCard({super.key, required this.todaySales});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todaysSales.toUpperCase(),
            style: AppTextStyles.labelSmall().copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 3 KPI tiles: CHEKLAR / TUSHUM / O'RTA (count, paid, average)
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  value: todaySales.totalSales.toString(),
                  label: l10n.saleCount,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiTile(
                  value: NumberFormatter.format(todaySales.totalPaid),
                  label: l10n.paid,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiTile(
                  value: NumberFormatter.format(todaySales.totalAmount),
                  label: l10n.totalSum,
                ),
              ),
            ],
          ),
          if (todaySales.debtAmount > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.onDebt,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${NumberFormatter.format(todaySales.debtAmount)} ${l10n.currencySom}',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String value;
  final String label;

  const _KpiTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColors.brandDark,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: AppColors.brandDark,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
