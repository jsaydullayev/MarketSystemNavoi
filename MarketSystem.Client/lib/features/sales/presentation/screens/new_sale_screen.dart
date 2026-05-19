import 'package:flutter/material.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/sales/presentation/widgets/payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/price_input_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/sale_body.dart';
import 'package:market_system_client/features/sales/presentation/widgets/external_product_sheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/customer_service.dart';
import '../../../../core/providers/auth_provider.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  List<dynamic> _products = [];
  List<dynamic> _customers = [];
  final List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _selectedCustomer;

  bool _isLoading = false;

  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    _loadData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final set = <String>{};
    for (final p in _products) {
      final cat = p['categoryName'];
      if (cat is String && cat.trim().isNotEmpty) set.add(cat.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategoryName = category;
    });
    _filterProducts();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final matchesSearch = query.isEmpty || name.contains(query);
        final matchesCategory = _selectedCategoryName == null ||
            product['categoryName'] == _selectedCategoryName;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  double get _totalAmount => _cartItems.totalAmount;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);
      final customerService = CustomerService(authProvider: authProvider);

      final products = await productService.getAllProducts();
      final customers = await customerService.getAllCustomers();

      setState(() {
        _products = products;
        _filteredProducts = products;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _addToCart(dynamic product) {
    final l10n = AppLocalizations.of(context)!;
    PriceInputSheet.show(
      context,
      product: product,
      onConfirm: (price, qty, comment) {
        setState(() {
          _cartItems.add({
            'productId': product['id'],
            'productName': product['name'],
            'salePrice': price,
            'quantity': qty,
            'comment': comment,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product['name']} ${l10n.returnSuccess}"),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  void _addExternalProduct() {
    final l10n = AppLocalizations.of(context)!;
    ExternalProductSheet.show(
      context,
      onConfirm: (name, costPrice, qty, salePrice, comment) {
        setState(() {
          _cartItems.add({
            'isExternal': true, // External product flag
            'externalCostPrice': costPrice, // Cost price for external products
            'productId': null, // External products don't have an id
            'productName': name,
            'salePrice': salePrice,
            'quantity': qty,
            'comment': comment,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name ${l10n.returnSuccess}'),
            backgroundColor: AppColors.brand,
          ),
        );
      },
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, double newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
    } else {
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }
  }

  void _editItemPrice(int index, Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final currentQuantity = item['quantity'] is num
        ? (item['quantity'] as num).toDouble()
        : 1.0;

    PriceInputSheet.show(context, product: {
      'name': item['productName'] ?? l10n.unknownProduct,
      'salePrice': (item['salePrice'] ?? 0.0).toDouble(),
      'minSalePrice': (item['minSalePrice'] ?? 0.0).toDouble(),
      'costPrice': (item['costPrice'] ?? 0.0).toDouble(),
      'id': item['productId'] ?? '',
      'unitName': (item['unitName'] ?? 'dona'),
      'initialQuantity': currentQuantity,
    }, onConfirm: (newPrice, newQuantity, comment) {
      setState(() {
        _cartItems[index]['salePrice'] = newPrice;
        _cartItems[index]['quantity'] = newQuantity;
        if (comment != null && comment.isNotEmpty) {
          _cartItems[index]['comment'] = comment;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item['productName']} ${l10n.itemUpdated}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _showCustomerDialog() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              child: Row(
                children: [
                  Text(
                    l10n.selectCustomerTitle,
                    style: AppTextStyles.titleMedium(),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _customers.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noCustomersFound,
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                      itemCount: _customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        final name = customer['fullName'] ?? l10n.unknown;
                        final phone = customer['phone'] ?? '';
                        final isSelected =
                            _selectedCustomer?['id'] == customer['id'];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCustomer = customer;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandLight
                                  : AppColors.inputFill,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brand
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSelected
                                      ? AppColors.brand
                                      : AppColors.textMuted,
                                  child: Text(
                                    name.toString().isNotEmpty
                                        ? name.toString()[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: AppTextStyles.labelLarge(),
                                      ),
                                      if (phone.isNotEmpty)
                                        Text(
                                          phone,
                                          style:
                                              AppTextStyles.bodySmall().copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppColors.brand),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.xl2),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(String? saleId) {
    final l10n = AppLocalizations.of(context)!;

    final cartSnapshot = List<Map<String, dynamic>>.from(_cartItems);
    final customerSnapshot = _selectedCustomer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        saleId: saleId ?? '',
        totalAmount: _totalAmount,
        selectedCustomer: customerSnapshot,
        onConfirm: (payments, useDebt, customer) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            // Use the customer the dialog returns — it may be one the
            // cashier created inline from the debt row, which the
            // pre-dialog snapshot wouldn't have.
            final sale = await salesService.createSale(
              customerId: customer?['id'],
            );
            final finalSaleId = sale['id'];

            for (var item in cartSnapshot) {
              if (item['isExternal'] == true) {
                // External product - add through external endpoint
                await salesService.addSaleItem(
                  saleId: finalSaleId,
                  isExternal: true,
                  externalProductName: item['productName'],
                  externalCostPrice: item['externalCostPrice'] ?? 0.0,
                  quantity: item['quantity'],
                  salePrice: item['salePrice'],
                  minSalePrice: 0.0,
                  comment: item['comment'],
                );
              } else {
                // Regular product
                await salesService.addSaleItem(
                  saleId: finalSaleId,
                  productId: item['productId'],
                  quantity: item['quantity'],
                  salePrice: item['salePrice'],
                  minSalePrice: item['minSalePrice'] ?? 0.0,
                  comment: item['comment'],
                );
              }
            }

            for (var payment in payments) {
              await salesService.addPayment(
                saleId: finalSaleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
              );
            }

            if (useDebt && payments.isEmpty) {
              await salesService.markSaleAsDebt(finalSaleId);
            }

            if (!mounted) return;

            setState(() {
              _cartItems.clear();
              _selectedCustomer = null;
            });

            navigator.pop();
            scaffoldMessenger.showSnackBar(SnackBar(
              content: Text(useDebt ? l10n.saleAsDebt : l10n.saleSuccess),
              backgroundColor: AppColors.success,
            ));
            navigator.pop(true);
          } catch (e) {
            if (!mounted) return;
            navigator.pop();
            scaffoldMessenger.showSnackBar(SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: AppColors.danger,
            ));
          }
        },
      ),
    );
  }

  Future<void> _completeSale() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cartEmptyWarning),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    _showPaymentDialog(null);
  }

  Future<void> _saveAsDraft() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cartItems.isEmpty) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      final sale = await salesService.createSale(
        customerId: _selectedCustomer?['id'],
      );

      for (var item in _cartItems) {
        if (item['isExternal'] == true) {
          // External product draft
          await salesService.addSaleItem(
            saleId: sale['id'],
            isExternal: true,
            externalProductName: item['productName'],
            externalCostPrice: item['externalCostPrice'] ?? 0.0,
            quantity: item['quantity'],
            salePrice: item['salePrice'],
            minSalePrice: 0.0,
            comment: item['comment'],
          );
        } else {
          // Regular product draft
          await salesService.addSaleItem(
            saleId: sale['id'],
            productId: item['productId'],
            quantity: item['quantity'],
            salePrice: item['salePrice'],
            minSalePrice: item['minSalePrice'] ?? 0.0,
            comment: item['comment'],
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.draftSaved),
            backgroundColor: AppColors.brand,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.draftSaveError}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Returns true when the screen should pop, false to stay on it.
  /// Three branches based on dialog answer:
  ///   - Save  → persist the cart as a Draft sale, then pop.
  ///   - Discard → just pop, throw away local cart state.
  ///   - Dismiss (tap outside) → treat as "stay", do NOT pop. Accidental
  ///     tap should not throw away an in-progress sale.
  Future<bool> _onWillPop() async {
    if (_cartItems.isEmpty) {
      return true;
    }
    final l10n = AppLocalizations.of(context)!;

    // `null` = dismissed (tap-outside / back), `'save'` / `'discard'` = explicit.
    final action = await showDialog<String>(
      context: context,
      // Tap-outside is allowed but treated as cancel (no pop).
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        backgroundColor: AppColors.surface,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.shopping_cart_checkout_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                l10n.saveSaleTitle,
                style: AppTextStyles.labelLarge(),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.draftSavePrompt(_cartItems.length),
          style: AppTextStyles.bodySmall().copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'discard'),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger),
            label: Text(
              l10n.discardSale,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'save'),
            icon: const Icon(Icons.bookmark_add_rounded, size: 18),
            label: Text(
              l10n.saveDraft,
              style: AppTextStyles.bodySmall().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );

    if (action == 'save') {
      await _saveAsDraft();
      return true;
    }
    if (action == 'discard') {
      return true;
    }
    // Dismissed — stay on screen.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _cartItems.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(l10n),
        body: SaleBody(
          isLoading: _isLoading,
          filteredProducts: _filteredProducts,
          cartItems: _cartItems,
          selectedCustomer: _selectedCustomer,
          totalAmount: _totalAmount,
          searchController: _searchController,
          onSelectCustomer: _showCustomerDialog,
          onAddToCart: _addToCart,
          onAddExternalProduct: _addExternalProduct,
          onUpdateQuantity: _updateQuantity,
          onRemoveFromCart: _removeFromCart,
          onEditPrice: _editItemPrice,
          categories: _categories,
          selectedCategoryName: _selectedCategoryName,
          onCategorySelected: _onCategorySelected,
        ),
        bottomNavigationBar: _buildCartBar(l10n),
      ),
    );
  }

  /// Sticky POS header — back button, title with meta-line, customer chip.
  /// White surface, bottom soft border, matches the demo's `.pos-header`.
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
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
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                _PosBackButton(
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.newSale,
                        style: AppTextStyles.labelLarge().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _headerMeta(),
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _CustomerChip(
                  customer: _selectedCustomer,
                  fallbackLabel: l10n.customer,
                  onTap: _showCustomerDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Meta line under the title — receipt number + current time.
  /// Mirrors the demo's "Chek #1247 · 14:25" hint without inventing a seller
  /// chip (the demo's seller badge is hardcoded; we omit it rather than fake).
  String _headerMeta() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    // Receipt number isn't known until the sale is created; use a time-based
    // placeholder so the meta line still reads naturally.
    return 'Chek · $hh:$mm';
  }

  /// Pinned bottom cart bar. Empty cart → primary button disabled but still
  /// visible (lets the user know it's there). Items present → summary row +
  /// orange checkout button driven by `AppPrimaryButton`.
  Widget _buildCartBar(AppLocalizations l10n) {
    final hasItems = _cartItems.isNotEmpty;
    final itemNames = _cartItems
        .take(3)
        .map((e) => (e['productName'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .join(', ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasItems) ...[
                _CartSummaryRow(
                  itemCount: _cartItems.length,
                  itemNames: itemNames,
                  total: _totalAmount,
                  onTap: _showCartSheet,
                  productsSuffix: l10n.productsInCartSuffix,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppPrimaryButton(
                label: hasItems
                    ? '${l10n.processReturn.replaceAll(l10n.returnText, l10n.saleText)} · ${NumberFormatter.format(_totalAmount)}'
                    : l10n.processReturn
                        .replaceAll(l10n.returnText, l10n.saleText),
                icon: Icons.credit_card_rounded,
                onPressed: hasItems ? _completeSale : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCartSheet() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 12, 8),
                        child: Row(
                          children: [
                            Text(
                              l10n.cartTitle,
                              style: AppTextStyles.titleMedium(),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brandLight,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Text(
                                '${_cartItems.length}',
                                style: AppTextStyles.labelSmall().copyWith(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _cartItems.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.cartEmptyWarning,
                                  style:
                                      AppTextStyles.bodySmall().copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                    16, 4, 16, 16),
                                itemCount: _cartItems.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) =>
                                    _buildCartSheetItem(
                                  index,
                                  _cartItems[index],
                                  l10n,
                                  () => setSheet(() {}),
                                ),
                              ),
                      ),
                      _buildCartSheetFooter(
                        l10n,
                        () {
                          Navigator.pop(ctx);
                          _completeSale();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartSheetItem(
    int index,
    Map<String, dynamic> item,
    AppLocalizations l10n,
    VoidCallback refreshSheet,
  ) {
    final isExternal = item['isExternal'] ?? false;
    final qty = (item['quantity'] as num).toDouble();
    final price = (item['salePrice'] as num).toDouble();
    final subtotal = qty * price;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isExternal ? AppColors.brandLight : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isExternal ? AppColors.brandTint : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isExternal
                      ? AppColors.brandTint
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isExternal
                      ? Icons.add_business_rounded
                      : Icons.inventory_2_rounded,
                  color:
                      isExternal ? AppColors.brand : AppColors.textSecondary,
                  size: 18,
                ),
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'] ?? '',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: isExternal
                            ? AppColors.brandDark
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    2.height,
                    Text(
                      '${qty % 1 == 0 ? qty.toInt() : qty} × ${NumberFormatter.format(price)}',
                      style: AppTextStyles.caption().copyWith(
                        letterSpacing: 0,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormatter.format(subtotal),
                style: AppTextStyles.bodySmall().copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          10.height,
          Row(
            children: [
              _SheetQtyBtn(
                icon: Icons.remove_rounded,
                onTap: () {
                  _updateQuantity(index, qty - 1);
                  refreshSheet();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
                  style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
                ),
              ),
              _SheetQtyBtn(
                icon: Icons.add_rounded,
                onTap: () {
                  _updateQuantity(index, qty + 1);
                  refreshSheet();
                },
              ),
              const Spacer(),
              _SheetActionBtn(
                icon: Icons.edit_rounded,
                color: AppColors.brand,
                onTap: () {
                  Navigator.pop(context);
                  _editItemPrice(index, item);
                },
              ),
              8.width,
              _SheetActionBtn(
                icon: Icons.delete_outline_rounded,
                color: AppColors.danger,
                onTap: () {
                  _removeFromCart(index);
                  refreshSheet();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSheetFooter(
    AppLocalizations l10n,
    VoidCallback onCheckout,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.brandTint),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalSum,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    NumberFormatter.format(_totalAmount),
                    style: AppTextStyles.titleLarge().copyWith(
                      color: AppColors.brand,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            12.height,
            AppPrimaryButton(
              label: l10n.processReturn
                  .replaceAll(l10n.returnText, l10n.saleText),
              icon: Icons.check_circle_outline,
              onPressed: _cartItems.isEmpty ? null : onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

/// Round back button for the POS header — 36×36, grey-fill, matches
/// the demo's `.pos-back` element.
class _PosBackButton extends StatelessWidget {
  const _PosBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

/// Customer chip — pill button shown in the POS header. When no customer is
/// selected, shows the fallback "Mijoz" label with a person glyph. When
/// selected, shows an orange-initial avatar followed by the customer name.
class _CustomerChip extends StatelessWidget {
  const _CustomerChip({
    required this.customer,
    required this.fallbackLabel,
    required this.onTap,
  });

  final Map<String, dynamic>? customer;
  final String fallbackLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCustomer = customer != null;
    final name = hasCustomer
        ? (customer!['fullName']?.toString() ?? fallbackLabel)
        : fallbackLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 6),
            decoration: BoxDecoration(
              color: hasCustomer ? AppColors.brandLight : AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasCustomer)
                  _InitialAvatar(name: name)
                else
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall().copyWith(
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                      color: hasCustomer
                          ? AppColors.brand
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 18×18 orange-tinted circle showing the customer's first initial. Used by
/// the header customer chip when a customer is selected.
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: AppTextStyles.caption().copyWith(
          fontSize: 10,
          color: Colors.white,
          letterSpacing: 0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tappable summary row above the pay button — "3 ta mahsulot · Coca-Cola,
/// Non, Pepsi" on the left and the running total on the right. Tapping it
/// opens the editable cart sheet.
class _CartSummaryRow extends StatelessWidget {
  const _CartSummaryRow({
    required this.itemCount,
    required this.itemNames,
    required this.total,
    required this.onTap,
    required this.productsSuffix,
  });

  final int itemCount;
  final String itemNames;
  final double total;
  final VoidCallback onTap;
  final String productsSuffix;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: '$itemCount $productsSuffix',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (itemNames.isNotEmpty)
                      TextSpan(text: ' · $itemNames'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              NumberFormatter.format(total),
              style: AppTextStyles.titleLarge().copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 32×32 minus/plus quantity button used inside the cart sheet rows. Orange
/// tint matches the brand accent.
class _SheetQtyBtn extends StatelessWidget {
  const _SheetQtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 16, color: AppColors.brand),
      ),
    );
  }
}

/// 32×32 action button (edit / delete) for cart sheet rows. Color comes from
/// the caller so we can flex it between brand-orange and danger-red.
class _SheetActionBtn extends StatelessWidget {
  const _SheetActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
