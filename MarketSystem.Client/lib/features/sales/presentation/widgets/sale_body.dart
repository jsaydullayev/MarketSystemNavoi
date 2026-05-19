import 'package:flutter/material.dart';
import '../../../../core/extensions/app_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class SaleBody extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> filteredProducts;
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? selectedCustomer;
  final double totalAmount;
  final VoidCallback onSelectCustomer;
  final Function(dynamic) onAddToCart;
  final Function(int, double) onUpdateQuantity;
  final Function(int) onRemoveFromCart;
  final Function(int, Map<String, dynamic>) onEditPrice;
  final TextEditingController searchController;
  final VoidCallback onAddExternalProduct;

  // Category filter chips.
  final List<String> categories;
  final String? selectedCategoryName;
  final ValueChanged<String?> onCategorySelected;

  const SaleBody({
    super.key,
    required this.isLoading,
    required this.filteredProducts,
    required this.cartItems,
    required this.selectedCustomer,
    required this.totalAmount,
    required this.onSelectCustomer,
    required this.onAddToCart,
    required this.onUpdateQuantity,
    required this.onRemoveFromCart,
    required this.onEditPrice,
    required this.searchController,
    required this.onAddExternalProduct,
    required this.categories,
    required this.selectedCategoryName,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    return Column(
      children: [
        _buildSearchRow(l10n),
        if (categories.isNotEmpty) _buildCategoryChips(l10n),
        Expanded(child: _buildProductGrid(l10n)),
      ],
    );
  }

  /// Search input plus the orange "add external product" button. White
  /// stripe under the POS header — matches the demo's `.pos-search` area
  /// (we lay it directly inside the page body since the screen's AppBar
  /// already carries the title/customer chip).
  Widget _buildSearchRow(AppLocalizations l10n) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.searchProduct,
                hintStyle: AppTextStyles.bodyMedium().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.inputFill,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.lg + 2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide:
                      const BorderSide(color: AppColors.brand, width: 1.5),
                ),
              ),
            ),
          ),
          10.width,
          _buildExternalProductButton(l10n),
        ],
      ),
    );
  }

  /// Orange add-external-product button — the same affordance as before
  /// but with the new brand color.
  Widget _buildExternalProductButton(AppLocalizations l10n) {
    return Tooltip(
      message: l10n.addExternalProduct,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: InkWell(
            onTap: onAddExternalProduct,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: const SizedBox(
              height: 46,
              width: 46,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _PlusBadge(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppLocalizations l10n) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.lg),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => 8.width,
          itemBuilder: (context, i) {
            final isAll = i == 0;
            final name = isAll ? l10n.all : categories[i - 1];
            final isSelected = isAll
                ? selectedCategoryName == null
                : selectedCategoryName == categories[i - 1];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () =>
                    onCategorySelected(isAll ? null : categories[i - 1]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg + 2, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.brand : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: AppTextStyles.labelSmall().copyWith(
                        fontSize: 12,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(AppLocalizations l10n) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            12.height,
            Text(
              l10n.noProductsFound,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 2 cols on mobile, more on wider devices. Aspect ratio is tuned for
        // the tile layout below (name + price + stock + optional chip).
        final int crossAxisCount;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 400) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.05,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final p = filteredProducts[index];
            return _ProductTile(
              product: p,
              onAdd: () => onAddToCart(p),
            );
          },
        );
      },
    );
  }
}

/// Product tile matching the demo's `.product-tile` — white surface, 1px
/// border, 12px radius. Name (13/600), price in brand orange (14/700),
/// stock line (11/muted), warning yellow when low (≤5).
class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onAdd});

  final Map<String, dynamic> product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final stock = (product['quantity'] ?? 0).toDouble();
    final isInStock = stock > 0;
    final isLow = stock > 0 && stock <= 5;
    final isPopular = product['isPopular'] == true ||
        product['popular'] == true ||
        (product['salesCount'] is num &&
            (product['salesCount'] as num) > 50);

    return Opacity(
      opacity: isInStock ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInStock ? onAdd : null,
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg - 2),
              border: Border.all(
                color: AppColors.borderSoft,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormatter.format(product['salePrice']),
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isInStock ? AppColors.brand : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _stockLabel(stock, isLow, isInStock),
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 11,
                    letterSpacing: 0,
                    color: isLow
                        ? AppColors.warning
                        : AppColors.textMuted,
                    fontWeight:
                        isLow ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (isPopular) const _PopularChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stockLabel(double stock, bool isLow, bool isInStock) {
    final qty = stock == stock.toInt() ? stock.toInt().toString() : stock.toStringAsFixed(2);
    if (!isInStock) return 'Stok: 0';
    if (isLow) return '⚠ Stok: $qty';
    return 'Stok: $qty';
  }
}

/// Small "Mashhur" chip shown on popular products. Demo class `.pchip`.
class _PopularChip extends StatelessWidget {
  const _PopularChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'Mashhur',
        style: AppTextStyles.caption().copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Tiny white circle with a brand-orange plus glyph in it. Sits over the
/// storefront icon on the add-external-product button.
class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.add_rounded,
        color: AppColors.brand,
        size: 11,
      ),
    );
  }
}
