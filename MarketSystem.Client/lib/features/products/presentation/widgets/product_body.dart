// Products feature body — migrated to the new design system.
//
// Layout: search input below the screen AppBar, a 3-cell summary card
// (JAMI / KAM STOK / TUGADI), a horizontal-scroll category filter row,
// and a list of product rows. Visual design mirrors HTML demo page 7.1
// (`#page-prod-list`).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Products list body. Constructor preserved exactly — only the visual
/// layer changed.
class ProductsBody extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> products;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final Function(dynamic) onDelete;
  final Function(dynamic) onEdit;
  final Function(dynamic) onZakup;
  final bool isReadOnly;
  final bool canViewCostPrice;

  const ProductsBody({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.products,
    required this.searchController,
    required this.onRefresh,
    required this.onDelete,
    required this.onEdit,
    required this.onZakup,
    required this.isReadOnly,
    required this.canViewCostPrice,
  });

  @override
  State<ProductsBody> createState() => _ProductsBodyState();
}

class _ProductsBodyState extends State<ProductsBody> {
  // Filter chip state: null = "Hammasi" selected, '__low__' / '__out__'
  // are reserved synthetic filters; any other value is a real category name.
  String? _selectedFilter;

  static const String _filterLow = '__low__';
  static const String _filterOut = '__out__';

  List<String> get _categoryNames {
    final set = <String>{};
    for (final p in widget.products) {
      final cat = p['categoryName'];
      if (cat is String && cat.trim().isNotEmpty) set.add(cat.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  // Counts shown in the summary card. Computed off the full list passed in
  // by the parent so they remain stable across search queries — the parent
  // filters by search, but stock counts should reflect the full inventory.
  int get _total => widget.products.length;
  int get _lowStock => widget.products.where(_isLow).length;
  int get _outOfStock => widget.products.where(_isOut).length;

  bool _isOut(dynamic p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 0.0;
    return qty <= 0;
  }

  bool _isLow(dynamic p) {
    final qty = (p['quantity'] as num?)?.toDouble() ?? 0.0;
    final minThreshold = (p['minThreshold'] as num?)?.toDouble() ?? 0.0;
    return qty > 0 && qty <= minThreshold;
  }

  List<dynamic> get _displayed {
    final filter = _selectedFilter;
    if (filter == null) return widget.products;
    if (filter == _filterLow) {
      return widget.products.where(_isLow).toList();
    }
    if (filter == _filterOut) {
      return widget.products.where(_isOut).toList();
    }
    return widget.products
        .where((p) => p['categoryName'] == filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800), // Web cap.
        child: Column(
          children: [
            _SearchBar(controller: widget.searchController, l10n: l10n),
            Expanded(
              child: widget.isLoading && widget.products.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.brand))
                  : widget.errorMessage != null
                      ? _ErrorView(
                          message: widget.errorMessage!,
                          onRetry: widget.onRefresh,
                          l10n: l10n,
                        )
                      : _buildList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    final list = _displayed;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl4),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _SummaryCard(
            total: _total,
            lowStock: _lowStock,
            outOfStock: _outOfStock,
          ),
          const SizedBox(height: AppSpacing.lg),
          _FilterChipsRow(
            categories: _categoryNames,
            selected: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
            l10n: l10n,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (list.isEmpty)
            _EmptyView(l10n: l10n)
          else
            ...list.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProductRow(
                  product: p,
                  l10n: l10n,
                  onDelete: widget.onDelete,
                  onEdit: widget.onEdit,
                  onZakup: widget.onZakup,
                  isReadOnly: widget.isReadOnly,
                  canViewCostPrice: widget.canViewCostPrice,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sticky search input below the screen AppBar. Light gray fill, 14px radius,
/// search icon prefix — matches `.search-input-big` in the demo.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;

  const _SearchBar({required this.controller, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.search,
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
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// 3-cell summary card showing total count, low-stock count, and out-of-stock
/// count. Numeric values turn warning yellow / danger red. Demo class
/// `.prod-summary`.
class _SummaryCard extends StatelessWidget {
  final int total;
  final int lowStock;
  final int outOfStock;

  const _SummaryCard({
    required this.total,
    required this.lowStock,
    required this.outOfStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              value: total.toString(),
              label: 'JAMI',
              valueColor: AppColors.text,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              value: lowStock.toString(),
              label: 'KAM STOK',
              valueColor: AppColors.warning,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              value: outOfStock.toString(),
              label: 'TUGADI',
              valueColor: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _SummaryCell({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }
}

/// Horizontal-scroll filter chips row. First chip is "Hammasi" (selected
/// by default) and uses inverted colors when selected; the rest use the
/// light gray pill. Matches demo's `.sales-filter-bar`.
class _FilterChipsRow extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final AppLocalizations l10n;

  const _FilterChipsRow({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <_FilterChipData>[
      _FilterChipData(label: l10n.all, value: null),
      const _FilterChipData(
        label: 'Kam stok',
        value: _ProductsBodyState._filterLow,
        leadingIcon: Icons.warning_amber_rounded,
      ),
      const _FilterChipData(
        label: 'Tugadi',
        value: _ProductsBodyState._filterOut,
        leadingIcon: Icons.block_rounded,
      ),
      ...categories.map((c) => _FilterChipData(label: c, value: c)),
    ];

    return SizedBox(
      height: 34,
      child: ScrollConfiguration(
        // Hide the desktop scrollbar — the chips already imply horizontal scroll
        // through their overflow and visible scrollbars look out of place.
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => 8.width,
          itemBuilder: (context, i) {
            final chip = chips[i];
            final isSelected = selected == chip.value;
            return _FilterChip(
              label: chip.label,
              leadingIcon: chip.leadingIcon,
              isSelected: isSelected,
              onTap: () => onSelected(isSelected ? null : chip.value),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final String? value;
  final IconData? leadingIcon;
  const _FilterChipData({
    required this.label,
    required this.value,
    this.leadingIcon,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg + 2, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.text : AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 14,
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                ),
                4.width,
              ],
              Text(
                label,
                style: AppTextStyles.labelSmall().copyWith(
                  fontSize: 12,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single product row matching the demo's `.prod-row`. 12px radius, 1px
/// soft border, white surface, 48x48 emoji tile on the left, name + category
/// in the middle, price + stock on the right. Out-of-stock items fade.
class _ProductRow extends StatelessWidget {
  final dynamic product;
  final AppLocalizations l10n;
  final Function(dynamic) onDelete;
  final Function(dynamic) onEdit;
  final Function(dynamic) onZakup;
  final bool isReadOnly;
  final bool canViewCostPrice;

  const _ProductRow({
    required this.product,
    required this.l10n,
    required this.onDelete,
    required this.onEdit,
    required this.onZakup,
    required this.isReadOnly,
    required this.canViewCostPrice,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canZakup = authProvider.user?['role'] == 'Admin' ||
        authProvider.user?['role'] == 'Owner';

    final qty = (product['quantity'] as num?)?.toDouble() ?? 0.0;
    final minThreshold =
        (product['minThreshold'] as num?)?.toDouble() ?? 0.0;
    final isOut = qty <= 0;
    final isLow = !isOut && qty <= minThreshold;
    final isPopular = product['isPopular'] == true ||
        product['popular'] == true ||
        (product['salesCount'] is num &&
            (product['salesCount'] as num) > 50);

    Widget row = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        border: Border.all(color: AppColors.borderSoft, width: 1),
      ),
      child: Row(
        children: [
          _EmojiTile(product: product),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        product['name']?.toString() ?? 'N/A',
                        style: AppTextStyles.bodySmall().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 6),
                      const _PopularChip(),
                    ],
                  ],
                ),
                if (product['categoryName'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product['categoryName'].toString(),
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 11,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (canViewCostPrice && product['costPrice'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.costPrice}: ${NumberFormatter.format(product['costPrice'])}',
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 10,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                NumberFormatter.format(product['salePrice']),
                style: AppTextStyles.bodyMedium().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 2),
              _StockLabel(
                qty: qty,
                unitName: product['unitName']?.toString() ?? l10n.piece,
                isLow: isLow,
                isOut: isOut,
              ),
            ],
          ),
          if (canZakup && !isReadOnly) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => onZakup(product),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
                size: 20,
                color: AppColors.brand,
              ),
              tooltip: l10n.zakup,
            ),
          ],
        ],
      ),
    );

    if (isOut) {
      row = Opacity(opacity: 0.55, child: row);
    }

    // Read-only sellers see static rows. Editors keep swipe-to-edit /
    // swipe-to-delete behavior so the rest of the CRUD flow stays intact.
    if (isReadOnly) {
      return row;
    }

    return Dismissible(
      key: Key('product_${product['id']}'),
      background: _buildSwipeBg(
        color: AppColors.brand,
        icon: Icons.edit_rounded,
        label: 'Edit',
        align: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBg(
        color: AppColors.danger,
        icon: Icons.delete_forever_rounded,
        label: l10n.delete,
        align: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit(product);
          return false;
        }
        return await _confirmDelete(context);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete(product);
        }
      },
      child: row,
    );
  }

  Widget _buildSwipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment align,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
      ),
      alignment: align,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl)),
            title: Text(l10n.confirmDelete),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.no,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.yes,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// 48x48 light-gray tile holding a product icon. Demo shows an emoji, but
/// product records don't carry one — we render the inventory icon in the
/// muted color so the row still gets the visual anchor.
class _EmojiTile extends StatelessWidget {
  final dynamic product;
  const _EmojiTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md + 1),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }
}

/// Stock label on the right edge of each row. Muted by default, warning
/// yellow for low stock, danger red when fully out.
class _StockLabel extends StatelessWidget {
  final double qty;
  final String unitName;
  final bool isLow;
  final bool isOut;

  const _StockLabel({
    required this.qty,
    required this.unitName,
    required this.isLow,
    required this.isOut,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    if (isOut) {
      color = AppColors.danger;
      text = 'Tugadi';
    } else if (isLow) {
      color = AppColors.warning;
      text = 'Stok: ${NumberFormatter.formatQuantity(qty)}';
    } else {
      color = AppColors.textMuted;
      text = 'Stok: ${NumberFormatter.formatQuantity(qty)}';
    }
    return Text(
      text,
      style: AppTextStyles.caption().copyWith(
        fontSize: 11,
        letterSpacing: 0,
        fontWeight: (isLow || isOut) ? FontWeight.w600 : FontWeight.w400,
        color: color,
      ),
    );
  }
}

/// "Mashhur" chip — brand-light pill with brand-orange text, used on
/// products flagged as popular.
class _PopularChip extends StatelessWidget {
  const _PopularChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'Mashhur',
        style: AppTextStyles.caption().copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: AppColors.textMuted,
          ),
          16.height,
          Text(
            l10n.noProducts,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final AppLocalizations l10n;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.danger,
          ),
          16.height,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColors.danger,
            ),
          ),
          24.height,
          SizedBox(
            width: 200,
            child: AppPrimaryButton(
              label: l10n.loading,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
