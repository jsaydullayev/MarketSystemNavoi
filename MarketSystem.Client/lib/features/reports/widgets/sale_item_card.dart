import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Row card for one product sold within the daily details list.
///
/// Demo reference: top-products list in `id="page-rpt-top"` — neutral
/// surface card, product name on the left, revenue in success green on
/// the right, a brand-tinted qty pill below, and a profit footer (green
/// when positive, danger when negative).
///
/// `isDark` stays on the constructor for source compatibility but is
/// ignored — the migrated design is light-only.
class SaleItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;

  const SaleItemCard({super.key, required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = item['productName'] as String? ?? l10n.unknownProduct;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final revenue = (item['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final profit =
        item['profit'] is num ? (item['profit'] as num).toDouble() : null;

    final qtyStr = qty % 1 == 0
        ? '${qty.toInt()} ${l10n.piece}'
        : '${qty.toStringAsFixed(1)} ${l10n.piece}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${NumberFormatter.formatDecimal(revenue)} ${l10n.currencySom}',
                style: AppTextStyles.bodyLarge().copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg - 2, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 13, color: AppColors.brand),
                    const SizedBox(width: 5),
                    Text(
                      qtyStr,
                      style: AppTextStyles.labelSmall().copyWith(
                        fontSize: 12,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profit != null) ...[
            const SizedBox(height: AppSpacing.md + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
              decoration: BoxDecoration(
                color: profit >= 0
                    ? AppColors.successLight
                    : AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (profit >= 0 ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        profit >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color:
                            profit >= 0 ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.netProfit,
                        style: AppTextStyles.bodySmall().copyWith(
                          fontWeight: FontWeight.w600,
                          color: profit >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          profit >= 0 ? AppColors.success : AppColors.danger,
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
