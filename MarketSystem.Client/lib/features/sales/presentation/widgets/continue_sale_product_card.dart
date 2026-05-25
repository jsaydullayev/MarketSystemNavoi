import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Compact product tile shown in the "continue sale" product grid.
///
/// Visual follows the demo's `.product-tile` in `#page-pos`: a white surface
/// with a soft 1-px border, the product name on top, the brand-orange price
/// in the middle, and a stock-count label at the bottom. Out-of-stock tiles
/// are washed out and disabled.
class ContinueSaleProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const ContinueSaleProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quantity = (product['quantity'] as num?)?.toDouble() ?? 0.0;
    final isInStock = quantity > 0;
    final isLow = quantity > 0 && quantity <= 5;

    // Stock color logic: out → muted grey, low → warning amber, healthy →
    // brand orange (matches the demo's `.low` accent on tight stock).
    final stockColor = !isInStock
        ? context.colors.textMuted
        : isLow
        ? AppColors.warning
        : context.colors.brand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInStock ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isInStock
                ? context.colors.surface
                : context.colors.inputFill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isInStock
                  ? context.colors.border
                  : context.colors.borderSoft,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Product name — 2-line clamp so wide names don't push the
                // price off the tile.
                Text(
                  product['name'] ?? l10n.unknown,
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isInStock
                        ? context.colors.text
                        : context.colors.textMuted,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Brand-orange price — matches demo `.pprice`.
                Text(
                  '${NumberFormatter.format(product['salePrice'])} ${l10n.currencySom}',
                  style: AppTextStyles.labelLarge().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isInStock
                        ? context.colors.brand
                        : context.colors.textMuted,
                  ),
                ),
                // Stock label — colored dot + count. Low stock turns amber.
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${quantity % 1 == 0 ? quantity.toInt() : quantity}',
                        style: AppTextStyles.caption().copyWith(
                          color: stockColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
