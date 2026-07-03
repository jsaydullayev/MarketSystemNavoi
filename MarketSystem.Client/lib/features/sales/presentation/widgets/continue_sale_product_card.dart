import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/api_constants.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import 'product_image_view.dart';

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
    final hasImage = (product['imageUrl'] as String?)?.isNotEmpty == true;
    // Narxi yashirilgan mahsulot: POS sotuv oynasida narx hech kimga
    // ko'rsatilmaydi (Owner/Admin/Seller). Mahsulotlar bo'limida ochiq qoladi.
    final hidePrice = product['hidePriceFromSellers'] == true;

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
        // Long-press → larger preview to confirm the product; independent of
        // the tap-to-add gesture. Works even when out of stock.
        onLongPress: () => showProductImagePreview(
          context,
          Map<String, dynamic>.from(product as Map),
          hidePrice: hidePrice,
        ),
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
              children: [
                // Prominent product photo (or placeholder) filling the top.
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: _image(context, hasImage),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name'] ?? l10n.unknown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isInStock
                        ? context.colors.text
                        : context.colors.textMuted,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hidePrice
                      ? '—'
                      : '${NumberFormatter.format(product['salePrice'])} ${l10n.currencySom}',
                  style: AppTextStyles.labelLarge().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: !hidePrice && isInStock
                        ? context.colors.brand
                        : context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
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

  Widget _image(BuildContext context, bool hasImage) {
    final placeholder = Container(
      color: context.colors.inputFill,
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_rounded,
        color: context.colors.textSecondary,
        size: 30,
      ),
    );
    if (!hasImage) return placeholder;
    final full = ApiConstants.productImageUrl(product['imageUrl'] as String?);
    if (full == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: full,
      fit: BoxFit.cover,
      memCacheWidth: 320,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}
