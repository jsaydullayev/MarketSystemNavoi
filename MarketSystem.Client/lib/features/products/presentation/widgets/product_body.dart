// Products feature body — migrated to the new design system.
//
// Layout: search input below the screen AppBar, a 3-cell summary card
// (JAMI / KAM STOK / TUGADI), a horizontal-scroll category filter row,
// and a list of product rows. Visual design mirrors HTML demo page 7.1
// (`#page-prod-list`).

import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import 'product_body_filter_chips.dart';
import 'product_body_product_row.dart';
import 'product_body_sections.dart';
import 'product_body_summary_card.dart';

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
    if (filter == kProductFilterLow) {
      return widget.products.where(_isLow).toList();
    }
    if (filter == kProductFilterOut) {
      return widget.products.where(_isOut).toList();
    }
    return widget.products.where((p) => p['categoryName'] == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Snapshot the widget field so the inline ternary below can compare a
    // local — `widget.errorMessage` is a getter access and wouldn't promote.
    final errorMessage = widget.errorMessage;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800), // Web cap.
        child: Column(
          children: [
            ProductSearchBar(controller: widget.searchController, l10n: l10n),
            Expanded(
              child: widget.isLoading && widget.products.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.brand,
                      ),
                    )
                  : errorMessage != null
                  ? ProductErrorView(
                      message: errorMessage,
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
    // Summary card + filter chips render once; only the product rows are
    // built lazily via ListView.builder so a large catalog (backend caps at
    // 5000) no longer constructs every row up-front on each rebuild.
    final leading = <Widget>[
      ProductSummaryCard(
        total: _total,
        lowStock: _lowStock,
        outOfStock: _outOfStock,
        l10n: l10n,
      ),
      const SizedBox(height: AppSpacing.lg),
      ProductFilterChipsRow(
        categories: _categoryNames,
        selected: _selectedFilter,
        onSelected: (value) => setState(() => _selectedFilter = value),
        l10n: l10n,
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
    final bodyCount = list.isEmpty ? 1 : list.length;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: context.colors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl4,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: leading.length + bodyCount,
        itemBuilder: (context, index) {
          if (index < leading.length) return leading[index];
          if (list.isEmpty) return ProductEmptyView(l10n: l10n);
          final p = list[index - leading.length];
          return Padding(
            key: ValueKey('product_${p['id']}'),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ProductRow(
              product: p,
              l10n: l10n,
              onDelete: widget.onDelete,
              onEdit: widget.onEdit,
              onZakup: widget.onZakup,
              isReadOnly: widget.isReadOnly,
              canViewCostPrice: widget.canViewCostPrice,
            ),
          );
        },
      ),
    );
  }
}
