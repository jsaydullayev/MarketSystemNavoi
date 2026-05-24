import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/models/cash_register_model.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// "TO'LOV TURLARI BO'YICHA" breakdown card.
///
/// Demo reference: the `.z-section` block titled `💵 TO'LOV TURLARI BO'YICHA`
/// inside `id="page-staff-shift"`. Section header in uppercase, rows of
/// label/value pairs, and a bold "JAMI" total row at the bottom.
class PaymentBreakdownCard extends StatelessWidget {
  final TodaySalesSummaryModel todaySales;

  const PaymentBreakdownCard({super.key, required this.todaySales});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final total =
        todaySales.cashPaid + todaySales.cardPaid + todaySales.clickPaid;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todaysIncomes.toUpperCase(),
            style: AppTextStyles.labelSmall().copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (todaySales.cashPaid > 0)
            _PaymentRow(label: l10n.cashMoney, amount: todaySales.cashPaid),
          if (todaySales.cardPaid > 0)
            _PaymentRow(label: l10n.bankCard, amount: todaySales.cardPaid),
          if (todaySales.clickPaid > 0)
            _PaymentRow(label: l10n.click, amount: todaySales.clickPaid),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(height: 1, color: context.colors.border),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalSum.toUpperCase(),
                  style: AppTextStyles.labelLarge().copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${NumberFormatter.format(total)} ${l10n.currencySom}',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: context.colors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final double amount;

  const _PaymentRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            '${NumberFormatter.format(amount)} ${l10n.currencySom}',
            style: AppTextStyles.bodyLarge().copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
