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
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:provider/provider.dart';

import '../../../data/services/product_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/dashboard_screen.dart';
import 'admin_product_form_screen.dart';
import 'widgets/admin_products_filter_chips.dart';
import 'widgets/admin_products_product_row.dart';
import 'widgets/admin_products_states.dart';

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
  StockFilter _filter = StockFilter.all;
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
        case StockFilter.all:
          break;
        case StockFilter.low:
          base = base.where((p) {
            final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
            final min = (p['minThreshold'] as num?)?.toDouble() ?? 0;
            return qty > 0 && qty <= min;
          });
          break;
        case StockFilter.out:
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
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
    // Snapshot the nullable state field so the inline ternary below can use
    // the local (which promotes through `!= null`) instead of `!`.
    final errorMessage = _errorMessage;

    return NetworkWrapper(
      onRetry: _loadProducts,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: AppBar(
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: context.colors.text,
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
              color: context.colors.text,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: context.colors.text),
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
                  color: context.colors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.brandTint, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.colors.brandDark,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.adminPriceTemporaryThresholdInfo,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: context.colors.brandDark,
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
                        icon: Icon(
                          Icons.clear_rounded,
                          color: context.colors.textSecondary,
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
            AdminProductsFilterChips(
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
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.brand,
                      ),
                    )
                  : errorMessage != null
                  ? AdminProductsErrorState(
                      message: errorMessage,
                      onRetry: _loadProducts,
                      l10n: l10n,
                    )
                  : _filteredProducts.isEmpty
                  ? AdminProductsEmptyState(
                      isSearching: _searchController.text.isNotEmpty,
                      l10n: l10n,
                    )
                  : RefreshIndicator(
                      color: context.colors.brand,
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
                          return AdminProductsProductRow(
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
          backgroundColor: context.colors.brand,
          foregroundColor: context.colors.onBrand,
          elevation: 4,
          onPressed: () => _openForm(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}
