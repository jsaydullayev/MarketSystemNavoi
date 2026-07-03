import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Hero banner shown above the daily sales detail list.
///
/// Demo reference: `id="page-rpt-hub"` — dark navy gradient hero
/// (`#0F172A` → `#1E293B`) with the headline metric, then a translucent
/// chip with the sales count. When profit is available it sits as a
/// secondary metric tile on the right.
///
/// The legacy `isDark` parameter is preserved on the constructor so callers
/// don't break, but the banner now always renders the demo-style dark
/// gradient (light mode only — the gradient itself is dark by design).
class DailySummaryBanner extends StatelessWidget {
  final double totalSales;
  final double? totalProfit;
  final int totalTx;
  final bool isDark;

  const DailySummaryBanner({
    super.key,
    required this.totalSales,
    required this.totalProfit,
    required this.totalTx,
    required this.isDark,
  });

  static const _heroStart = AppColors.heroGradientTop;
  static const _heroEnd = AppColors.heroGradientBottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.xl,
        AppSpacing.xl2,
        AppSpacing.xl2,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_heroStart, _heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalSale.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${NumberFormatter.formatDecimal(totalSales)} ${l10n.currencySom}',
                    style: AppTextStyles.displayMedium().copyWith(
                      color: Colors.white,
                      letterSpacing: -0.5,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    l10n.salesCount(totalTx),
                    style: AppTextStyles.labelSmall().copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (totalProfit case final profit?) ...[
            const SizedBox(width: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.netProfit.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
                    style: AppTextStyles.titleMedium().copyWith(
                      color: Colors.white,
                      fontSize: 16,
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
