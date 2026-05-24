import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Row card in the inventory list (Reports → Ombor tab).
///
/// Demo reference: list rows in `id="page-rpt-top"` — neutral surface
/// card, product name + a colored stock chip on the right (success >10,
/// warning >0, danger when out), then a 2-column info grid below and an
/// optional potential-profit footer when the viewer is the owner.
class InventoryItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isOwner;
  final bool canViewCostPrice;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.isOwner,
    this.canViewCostPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = item['productName'] as String? ?? l10n.unknown;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final costPrice = (item['costPrice'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (item['totalCostValue'] as num?)?.toDouble() ?? 0.0;
    final totalSale = (item['totalSaleValue'] as num?)?.toDouble() ?? 0.0;
    final potentialProfit = isOwner && item['potentialProfit'] != null
        ? (item['potentialProfit'] as num).toDouble()
        : null;

    final stockColor = qty > 10
        ? AppColors.success
        : qty > 0
        ? AppColors.warning
        : AppColors.danger;

    final qtyStr = qty % 1 == 0
        ? '${qty.toInt()} ${l10n.piece}'
        : '${qty.toStringAsFixed(1)} ${l10n.piece}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      qtyStr,
                      style: AppTextStyles.labelSmall().copyWith(
                        fontSize: 11,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Row(
            children: [
              if (canViewCostPrice)
                Expanded(
                  child: _InfoTile(
                    label: l10n.purchasePrice,
                    value:
                        '${NumberFormatter.formatDecimal(costPrice)} ${l10n.currencySom}',
                  ),
                ),
              if (canViewCostPrice) const Spacer(),
              Expanded(
                child: _InfoTile(
                  label: l10n.sellingPrice,
                  value:
                      '${NumberFormatter.formatDecimal(salePrice)} ${l10n.currencySom}',
                  align: canViewCostPrice
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (canViewCostPrice)
                Expanded(
                  child: _InfoTile(
                    label: l10n.totalCost,
                    value:
                        '${NumberFormatter.formatDecimal(totalCost)} ${l10n.currencySom}',
                  ),
                ),
              if (canViewCostPrice) const Spacer(),
              Expanded(
                child: _InfoTile(
                  label: l10n.totalValue,
                  value:
                      '${NumberFormatter.formatDecimal(totalSale)} ${l10n.currencySom}',
                  align: canViewCostPrice
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                ),
              ),
            ],
          ),
          if (isOwner && potentialProfit != null && potentialProfit != 0) ...[
            const SizedBox(height: AppSpacing.md + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: potentialProfit > 0
                    ? AppColors.successLight
                    : AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppRadius.md - 1),
              ),
              child: Row(
                children: [
                  Icon(
                    potentialProfit > 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: potentialProfit > 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${l10n.potentialProfit}: ${NumberFormatter.formatDecimal(potentialProfit)} ${l10n.currencySom}',
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: potentialProfit > 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _InfoTile({
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: AppTextStyles.bodySmall().copyWith(fontSize: 11)),
        Text(
          value,
          style: AppTextStyles.bodySmall().copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.text,
          ),
        ),
      ],
    );
  }
}
