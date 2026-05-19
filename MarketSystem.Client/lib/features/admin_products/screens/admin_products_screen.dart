// Admin Products list — migrated to the new design system.
//
// Layout follows HTML demo page 7.1 (`#page-prod-list`):
// - White AppBar with the screen title
// - Big search input (AppTextInput)
// - Filter chip strip (Hammasi / Kam stok / Tugadi)
// - Stacked product rows in AppCards (emoji tile + name/cat + price/stock)
// - Brand-orange FAB to open the product form
// - Pull-to-refresh + role gating preserved from the legacy screen.

import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:provider/provider.dart';

import '../../../data/services/product_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/dashboard_screen.dart';
import 'admin_product_form_screen.dart';

enum _StockFilter { all, low, out }

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  _StockFilter _filter = _StockFilter.all;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      Iterable<dynamic> base = _products;
      if (query.isNotEmpty) {
        base = base.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          return name.contains(query);
        });
      }
      switch (_filter) {
        case _StockFilter.all:
          break;
        case _StockFilter.low:
          base = base.where((p) {
            final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
            final min = (p['minThreshold'] as num?)?.toDouble() ?? 0;
            return qty > 0 && qty <= min;
          });
          break;
        case _StockFilter.out:
          base = base.where((p) {
            final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
            return qty <= 0;
          });
          break;
      }
      _filteredProducts = base.toList();
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final products = await productService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
      _filterProducts();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorWithMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(dynamic product) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteProductConfirm(product['name'] ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final productService = ProductService(authProvider: authProvider);
        await productService.deleteProduct(product['id']);
        _loadProducts();

        if (mounted) {
          _showSnack(l10n.productDeletedSuccess, isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnack(l10n.errorWithMessage(e.toString()), isError: true);
        }
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      margin: const EdgeInsets.all(AppSpacing.xl),
    ));
  }

  Future<void> _openForm({dynamic product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormScreen(product: product),
      ),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'];
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadProducts,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.text,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          title: Text(
            l10n.adminProductsManagement,
            style: AppTextStyles.titleMedium().copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
              onPressed: _loadProducts,
            ),
          ],
        ),
        body: Column(
          children: [
            // Info banner explaining the admin's edit scope.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.brandTint, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.brandDark,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.adminPriceTemporaryThresholdInfo,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.brandDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: AppTextInput(
                controller: _searchController,
                hint: l10n.searchProduct,
                prefixIcon: Icons.search_rounded,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts();
                        },
                      )
                    : null,
              ),
            ),
            // Filter chips
            _FilterChips(
              selected: _filter,
              onChanged: (f) {
                setState(() => _filter = f);
                _filterProducts();
              },
              l10n: l10n,
            ),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brand,
                      ),
                    )
                  : _errorMessage != null
                      ? _ErrorState(
                          message: _errorMessage!,
                          onRetry: _loadProducts,
                          l10n: l10n,
                        )
                      : _filteredProducts.isEmpty
                          ? _EmptyState(
                              isSearching:
                                  _searchController.text.isNotEmpty,
                              l10n: l10n,
                            )
                          : RefreshIndicator(
                              color: AppColors.brand,
                              onRefresh: _loadProducts,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xl,
                                  AppSpacing.lg,
                                  AppSpacing.xl,
                                  AppSpacing.xl4 * 2,
                                ),
                                itemCount: _filteredProducts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return _ProductRow(
                                    product: product,
                                    userRole: userRole,
                                    l10n: l10n,
                                    onEdit: () => _openForm(product: product),
                                    onDelete: () => _deleteProduct(product),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () => _openForm(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}

/// Filter chip row (Hammasi / Kam stok / Tugadi). Demo's `.sales-filter-bar`.
class _FilterChips extends StatelessWidget {
  final _StockFilter selected;
  final ValueChanged<_StockFilter> onChanged;
  final AppLocalizations l10n;

  const _FilterChips({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(String, _StockFilter, IconData?)>[
      (l10n.no == 'Yo\'q' ? 'Hammasi' : 'All', _StockFilter.all, null),
      ('Kam stok', _StockFilter.low, Icons.warning_amber_rounded),
      ('Tugadi', _StockFilter.out, Icons.block_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _Chip(
                  label: e.$1,
                  icon: e.$3,
                  active: e.$2 == selected,
                  onTap: () => onChanged(e.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? AppColors.brand : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single product card. Demo's `.prod-row` inside `id="page-prod-list"`.
class _ProductRow extends StatelessWidget {
  final dynamic product;
  final String? userRole;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.userRole,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qty = (product['quantity'] as num?)?.toDouble() ?? 0;
    final minThreshold =
        (product['minThreshold'] as num?)?.toDouble() ?? 0;
    final isOut = qty <= 0;
    final isLow = !isOut && qty <= minThreshold;
    final unitName = product['unitName'] ?? l10n.piece;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / icon tile
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.brandDark,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Name, category, badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? l10n.unknown,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.salePriceLabel(product['salePrice'] ?? 0),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.costPriceLabel(product['costPrice'] ?? 0),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (product['isTemporary'] == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _Pill(
                      label: l10n.temporary,
                      color: AppColors.brandDark,
                      bg: AppColors.brandLight,
                    ),
                  ),
                if (isLow)
                  _Pill(
                    label: l10n.lowStockWarning(
                      product['minThreshold'] ?? 0,
                    ),
                    color: AppColors.warning,
                    bg: AppColors.warningLight,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Price + stock + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.format(
                    (product['salePrice'] as num?)?.toDouble() ?? 0),
                style: AppTextStyles.bodyLarge().copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isOut
                    ? 'Tugadi'
                    : 'Stok: ${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2)} $unitName',
                style: AppTextStyles.bodySmall().copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOut
                      ? AppColors.danger
                      : (isLow
                          ? AppColors.warning
                          : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAction(
                    icon: Icons.edit_outlined,
                    color: AppColors.brand,
                    onTap: onEdit,
                    tooltip: l10n.edit,
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    onTap: onDelete,
                    tooltip: l10n.delete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  const _Pill({
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: 10,
              letterSpacing: 0.4,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final AppLocalizations l10n;
  const _EmptyState({required this.isSearching, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isSearching ? l10n.productNotFound : l10n.noProducts,
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: l10n.retry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
