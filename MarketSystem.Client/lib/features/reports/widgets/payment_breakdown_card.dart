import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Single row in the "byPaymentType" breakdown list.
///
/// Demo reference: payment-method rows in `id="page-rpt-profit"` and
/// `id="page-rpt-hub"` — neutral white surface card with a colored icon
/// tile on the left, label + transaction count + a thin progress bar in
/// the middle, and the formatted amount on the right.
///
/// The `color` per payment method is still a strong cue but the card
/// chrome is neutral so a column of rows reads as a single list, not a
/// pile of competing tinted blocks.
class ReportPaymentBreakdownCard extends StatelessWidget {
  final String paymentType;
  final double amount;
  final int count;
  final double totalSales;

  const ReportPaymentBreakdownCard({
    super.key,
    required this.paymentType,
    required this.amount,
    required this.count,
    required this.totalSales,
  });

  static const _config = {
    'Cash': {'icon': Icons.payments_outlined, 'color': AppColors.success},
    'Terminal': {
      // Fixed category marker colour (not the theme accent) — orange reads
      // fine on both light and dark, like the literal purple/blue below.
      'icon': Icons.credit_card_outlined,
      'color': Color(0xFFFF6B00),
    },
    'Transfer': {
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF8B5CF6),
    },
    'Click': {'icon': Icons.phone_android_outlined, 'color': Color(0xFF3B82F6)},
    'Qaytarilgan': {
      'icon': Icons.assignment_return_outlined,
      'color': AppColors.danger,
    },
    'Refund': {
      'icon': Icons.assignment_return_outlined,
      'color': AppColors.danger,
    },
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRefund = paymentType == 'Qaytarilgan' || paymentType == 'Refund';

    final cfg =
        _config[paymentType] ??
        {'icon': Icons.payment_outlined, 'color': context.colors.textMuted};
    final color = cfg['color'] as Color;
    final icon = cfg['icon'] as IconData;
    final String name;
    switch (paymentType) {
      case 'Cash':
        name = l10n.paymentCash;
        break;
      case 'Terminal':
        name = l10n.terminal;
        break;
      case 'Transfer':
        name = l10n.accountNumber;
        break;
      case 'Click':
        name = l10n.click;
        break;
      case 'Qaytarilgan':
      case 'Refund':
        name = l10n.paymentRefund;
        break;
      default:
        name = paymentType;
    }

    // For refunds, show absolute value but keep track of negative
    final displayAmount = amount.abs();
    final pct = totalSales > 0
        ? (displayAmount / totalSales * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md + 1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isRefund)
                  Text(
                    l10n.transactionStats(count, pct),
                    style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                  )
                else
                  Text(
                    count > 0 ? l10n.transactionStats(count, pct) : '',
                    style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                  ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalSales > 0
                        ? (isRefund ? displayAmount : amount) / totalSales
                        : 0,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      isRefund ? AppColors.danger : color,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '${isRefund ? '-' : ''}${NumberFormatter.formatDecimal(displayAmount)} ${l10n.currencySom}',
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.w700,
              color: isRefund ? AppColors.danger : color,
            ),
          ),
        ],
      ),
    );
  }
}
