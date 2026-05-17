import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/extensions/app_extensions.dart';

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

  // V2 — kategoriya filtri
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildTopSection(isDark, l10n, theme),
        _buildSearchRow(isDark, l10n),
        if (categories.isNotEmpty) _buildCategoryChips(isDark, l10n, theme),
        Expanded(child: _buildProductGrid(isDark, l10n, theme)),
      ],
    );
  }

  Widget _buildTopSection(bool isDark, AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildCustomerPill(isDark, l10n, theme)),
          10.width,
          _buildTotalPill(),
        ],
      ),
    );
  }

  Widget _buildCustomerPill(bool isDark, AppLocalizations l10n, ThemeData theme) {
    final hasCustomer = selectedCustomer != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelectCustomer,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.getBg(isDark),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded,
                  color: theme.primaryColor, size: 18),
              8.width,
              Expanded(
                child: Text(
                  hasCustomer
                      ? (selectedCustomer!['fullName'] ?? l10n.unknown)
                      : l10n.customerNotSelected,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Text(
        NumberFormatter.format(totalAmount),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF10B981),
        ),
      ),
    );
  }

  Widget _buildSearchRow(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: l10n.searchProduct,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.getCard(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              ),
            ),
          ),
          10.width,
          _buildExternalProductButton(isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildExternalProductButton(bool isDark, AppLocalizations l10n) {
    return Tooltip(
      message: l10n.addExternalProduct,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA85C), Color(0xFFF28C33)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.orangePrimary.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onAddExternalProduct,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              height: 48,
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 24,
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

  Widget _buildCategoryChips(
      bool isDark, AppLocalizations l10n, ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              borderRadius: BorderRadius.circular(20),
              onTap: () => onCategorySelected(isAll ? null : categories[i - 1]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
    bool isDark,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: Colors.grey.shade400),
            12.height,
            Text(
              l10n.noProductsFound,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tighter responsive grid — old aspect ratio of 0.75 with center-
        // aligned Column left a tall empty card with the content bunched in
        // the middle. New: ~1:1 aspect ratio, content top-aligned.
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final p = filteredProducts[index];
            return _ProductCard(
              product: p,
              isDark: isDark,
              theme: theme,
              onAdd: () => onAddToCart(p),
            );
          },
        );
      },
    );
  }
}

/// Compact product card used inside the New-Sale product grid. Icon top-left
/// (28×28 tile), name (2 lines max), price, then a footer row with the stock
/// indicator on the left and an add-to-cart button on the right. Greys-out
/// and disables interaction when stock is 0.
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.theme,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final stock = (product['quantity'] ?? 0).toDouble();
    final isInStock = stock > 0;
    final isLow = stock > 0 && stock <= 5;

    final stockColor = isLow
        ? const Color(0xFFFCD34D)
        : isInStock
            ? const Color(0xFF10B981)
            : Colors.grey;

    return Opacity(
      opacity: isInStock ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInStock ? onAdd : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: theme.primaryColor,
                    size: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormatter.format(product['salePrice']),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isInStock
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade400,
                    letterSpacing: -0.1,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        const SizedBox(width: 4),
                        Text(
                          _formatStock(stock),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: stockColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Color(0xFF3B82F6),
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

  String _formatStock(double n) {
    if (n == n.toInt()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}

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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.add_rounded,
        color: AppColors.orangePrimary,
        size: 11,
      ),
    );
  }
}
