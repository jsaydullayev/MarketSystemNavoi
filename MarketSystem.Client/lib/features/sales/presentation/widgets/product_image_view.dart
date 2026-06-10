// Product image helpers shared by the POS product grids (new-sale + continue-sale).
//
// Product images are an OPTIONAL aid for the cashier to visually identify a
// product while building a sale — most products have none. The display path is
// deliberately cheap: thumbnails are lazy-loaded and cached by
// `cached_network_image`, so a large grid scrolls just as smoothly as before
// the feature existed. The full-size preview opens only on long-press.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';

/// Small rounded product thumbnail. Falls back to a brand-tinted box icon when
/// the product has no image (the common case) or the URL fails to load — so it
/// never breaks the tile layout.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.radius = AppRadius.sm,
  });

  /// Raw server-relative path from the product DTO (`imageUrl`), or null.
  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final full = ApiConstants.productImageUrl(imageUrl);

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.5,
        color: context.colors.brand,
      ),
    );

    if (full == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: full,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Decode at ~thumbnail resolution, not the source megapixels.
        memCacheWidth: (size * 3).round(),
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// Opens a centered preview so the cashier can confirm which product they're
/// about to add. Shows the full image when present, otherwise a placeholder
/// with the name/price (still useful for disambiguation). Long-press entry
/// point — never interferes with the tap-to-add-to-cart gesture.
Future<void> showProductImagePreview(
  BuildContext context,
  Map<String, dynamic> product,
) {
  final full = ApiConstants.productImageUrl(product['imageUrl'] as String?);
  final name = product['name']?.toString() ?? '';
  final price = NumberFormatter.format(product['salePrice']);

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            // Cap the image to half the screen height so the dialog (image +
            // name + price) always fits. AspectRatio(1) made the image as tall
            // as the dialog width → 144px bottom overflow on tall/wide screens.
            // BoxFit.contain shows the WHOLE image; brand-tinted letterbox keeps
            // non-square images clean.
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.5,
              width: double.infinity,
              child: Container(
                color: context.colors.brandLight,
                child: full == null
                    ? const _PreviewPlaceholder()
                    : CachedNetworkImage(
                        imageUrl: full,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            const _PreviewPlaceholder(loading: true),
                        errorWidget: (_, __, ___) =>
                            const _PreviewPlaceholder(),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  price,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.colors.brand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.brandLight,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: context.colors.brand,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Rasm mavjud emas',
                  style: AppTextStyles.caption().copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
    );
  }
}
