// Products list screen — migrated to the new design system.
//
// Owns the data fetch + filtering for the products list. Visual layer (search
// row, summary card, filter chips, product rows, FAB) lives in
// `ProductsBody`. Quick-zakup bottom sheet kept inline because it is small
// and only used here.

import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/file_helper.dart'
    as core_file_helper;
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/products/presentation/screens/product_form_screen.dart';
import 'package:market_system_client/features/products/presentation/widgets/product_body.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/zakup_service.dart';
import '../../../../l10n/app_localizations.dart';

class ProductsScreen extends StatefulWidget {
  final bool isReadOnly;
  const ProductsScreen({super.key, this.isReadOnly = false});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
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
      _filteredProducts = query.isEmpty
          ? _products
          : _products
              .where((p) => (p['name'] ?? '').toLowerCase().contains(query))
              .toList();
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
      if (!mounted) return;
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final errorMsg = e.toString();
      setState(() {
        if (errorMsg.contains('SocketException') ||
            errorMsg.contains('Connection refused') ||
            errorMsg.contains('Failed to fetch')) {
          _errorMessage = "Serverga ulanib bo'lmadi";
        } else if (errorMsg.contains('401') ||
            errorMsg.contains('Unauthorized')) {
          _errorMessage = 'Sessiya tugadi, qayta kiring';
        } else if (errorMsg.contains('403') || errorMsg.contains('Forbidden')) {
          _errorMessage = "Sizga ruxsat yo'q";
        } else {
          _errorMessage = l10n.errorOccurred;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(dynamic product) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _products.removeWhere((p) => p['id'] == product['id']);
      _filteredProducts.removeWhere((p) => p['id'] == product['id']);
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ProductService(authProvider: authProvider)
          .deleteProduct(product['id']);
    } catch (e) {
      setState(() {
        _products.add(product);
        _filteredProducts.add(product);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productUsedInSales),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _quickZakup(dynamic product) async {
    final l10n = AppLocalizations.of(context)!;
    final qtyController = TextEditingController();
    final costController =
        TextEditingController(text: (product['costPrice'] ?? 0).toString());
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl3,
            AppSpacing.xl,
            AppSpacing.xl3,
            AppSpacing.xl4,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.brand,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.zakup,
                            style: AppTextStyles.caption().copyWith(
                              fontSize: 12,
                              letterSpacing: 0,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            product['name']?.toString() ?? '',
                            style: AppTextStyles.titleMedium()
                                .copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl3),
                _buildDialogField(qtyController, l10n.quantity,
                    Icons.add_shopping_cart, true),
                const SizedBox(height: AppSpacing.lg),
                _buildDialogField(costController, l10n.costPrice,
                    Icons.monetization_on_outlined, true),
                const SizedBox(height: AppSpacing.xl3),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: l10n.cancel,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 2,
                      child: AppPrimaryButton(
                        label: l10n.add,
                        onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ZakupService(authProvider: authProvider).createZakup(
          productId: product['id'],
          quantity: double.parse(qtyController.text),
          costPrice: double.parse(costController.text),
        );
        _loadProducts();
        _showSnackBar(l10n.zakupSuccess, AppColors.success);
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), AppColors.danger);
      }
    }
  }

  Widget _buildDialogField(TextEditingController controller, String label,
      IconData icon, bool isNum) {
    return TextField(
      controller: controller,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall(),
        prefixIcon: Icon(icon, size: 20, color: AppColors.brand),
        filled: true,
        fillColor: AppColors.inputFill,
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
    );
  }

  Future<void> _exportExcel() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bytes = await ProductService(authProvider: authProvider)
          .downloadProductsExcel();
      if (bytes != null && bytes.isNotEmpty) {
        await core_file_helper.FileHelper.saveAndOpenExcel(
            bytes, 'Mahsulotlar.xlsx');
      }
    } catch (e) {
      _showSnackBar(e.toString(), AppColors.danger);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  void _openProductForm({dynamic product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductBottomSheet(product: product),
    ).then((value) {
      if (value == true) _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canViewCostPrice = authProvider.user?['role'] != 'Seller';

    return NetworkWrapper(
      onRetry: _loadProducts,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(l10n),
        body: ProductsBody(
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          products: _filteredProducts,
          searchController: _searchController,
          onRefresh: _loadProducts,
          onDelete: _deleteProduct,
          onEdit: (p) => _openProductForm(product: p),
          onZakup: _quickZakup,
          isReadOnly: widget.isReadOnly,
          canViewCostPrice: canViewCostPrice,
        ),
        floatingActionButton: !widget.isReadOnly
            ? _ProductsFab(onTap: () => _openProductForm())
            : null,
      ),
    );
  }

  /// Sticky POS-style header: back arrow, centered title, export/refresh
  /// icon actions on the right. Matches the demo's `.pos-flow-header`.
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColors.text,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.products,
                      style: AppTextStyles.titleMedium().copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: _exportExcel,
                  tooltip: 'Excel',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: _loadProducts,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button — 56x56 brand-orange circle with a white plus
/// glyph and a soft brand shadow. Matches the demo's `.fab`.
class _ProductsFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ProductsFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Center(
              child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
