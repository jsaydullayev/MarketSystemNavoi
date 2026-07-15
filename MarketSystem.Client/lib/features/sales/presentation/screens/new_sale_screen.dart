import 'dart:async';

import 'package:flutter/material.dart';
import 'package:market_system_client/design/widgets/app_snackbar.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
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
import '../widgets/sale_pos_widgets.dart';
import '../widgets/sale_customer_sheet.dart';
import '../widgets/sale_cart_sheet.dart';

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

  // PERF: distinct category names, computed once when products load instead of
  // on every build (the old getter rebuilt+sorted a Set on each rebuild, i.e.
  // on every search keystroke and cart edit).
  List<String> _categories = const [];

  // PERF: debounce the search so filtering runs once after the cashier stops
  // typing — not a full-screen setState + list scan on every keystroke.
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _filterProducts();
    });
  }

  List<String> _computeCategories() {
    final set = <String>{};
    for (final p in _products) {
      final cat = p['categoryName'];
      if (cat is String && cat.trim().isNotEmpty) set.add(cat.trim());
    }
    return set.toList()..sort();
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
        final matchesCategory =
            _selectedCategoryName == null ||
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
        _categories = _computeCategories();
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
            'minSalePrice':
                (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
            'hidePriceFromSellers': product['hidePriceFromSellers'] == true,
            'quantity': qty,
            'comment': comment,
          });
        });

        showAppSnackBar(context, "${product['name']} ${l10n.returnSuccess}");
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

        showAppSnackBar(
          context,
          '$name ${l10n.returnSuccess}',
          kind: AppSnackKind.info,
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

    PriceInputSheet.show(
      context,
      product: {
        'name': item['productName'] ?? l10n.unknownProduct,
        'salePrice': (item['salePrice'] ?? 0.0).toDouble(),
        'minSalePrice': (item['minSalePrice'] ?? 0.0).toDouble(),
        'costPrice': (item['costPrice'] ?? 0.0).toDouble(),
        'hidePriceFromSellers': item['hidePriceFromSellers'] == true,
        'id': item['productId'] ?? '',
        'unitName': (item['unitName'] ?? 'dona'),
        'initialQuantity': currentQuantity,
      },
      onConfirm: (newPrice, newQuantity, comment) {
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
              content: Text('${item['productName']} ${l10n.itemUpdated}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  void _showCustomerDialog() {
    showCustomerSelectionSheet(
      context,
      customers: _customers,
      selectedId: _selectedCustomer?['id']?.toString(),
      onSelected: (c) => setState(() {
        // Quick-add orqali yaratilgan yangi mijozni ro'yxatga ham qo'shamiz —
        // shunda picker qayta ochilganda ko'rinadi. Mavjud mijoz tanlansa,
        // takror qo'shilmaydi (id bo'yicha tekshiramiz).
        final id = c['id']?.toString();
        if (id != null &&
            id.isNotEmpty &&
            !_customers.any((e) => (e as Map)['id']?.toString() == id)) {
          _customers.add(c);
        }
        _selectedCustomer = c;
      }),
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
        onConfirm: (payments, useDebt, customer, discount) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final salesService = SalesService(authProvider: authProvider);
          String? finalSaleId;
          // Items successfully added (saleItemId -> quantity). Lets the catch
          // below restore their stock if a later add/payment fails.
          final addedItems = <String, double>{};
          try {
            // Use the customer the dialog returns — it may be one the
            // cashier created inline from the debt row, which the
            // pre-dialog snapshot wouldn't have.
            final sale = await salesService.createSale(
              customerId: customer?['id'],
            );
            final saleId = sale['id'] as String;
            finalSaleId = saleId;

            // Add items SEQUENTIALLY. Each addSaleItem mutates rows shared
            // across the request — the sale's running total and the product's
            // stock — which carry optimistic-concurrency (xmin) tokens. Firing
            // them in parallel makes the writes collide and surface as a 409
            // ("Ma'lumot boshqa foydalanuvchi tomonidan o'zgartirildi"), even
            // for a single user. The extra latency is negligible for a cart.
            for (final item in cartSnapshot) {
              final dynamic added;
              if (item['isExternal'] == true) {
                added = await salesService.addSaleItem(
                  saleId: saleId,
                  isExternal: true,
                  externalProductName: item['productName'],
                  externalCostPrice: item['externalCostPrice'] ?? 0.0,
                  quantity: item['quantity'],
                  salePrice: item['salePrice'],
                  minSalePrice: 0.0,
                  comment: item['comment'],
                );
              } else {
                added = await salesService.addSaleItem(
                  saleId: saleId,
                  productId: item['productId'],
                  quantity: item['quantity'],
                  salePrice: item['salePrice'],
                  minSalePrice: item['minSalePrice'] ?? 0.0,
                  comment: item['comment'],
                );
              }
              _trackAddedItem(addedItems, added);
            }

            // Chegirma (skidka) — mahsulotlar qo'shilgach, to'lovdan OLDIN
            // yuboriladi. Backend sotuvning hisobini (TotalAmount) shu
            // summaga kamaytiradi, shunda quyidagi to'lovlar aynan
            // chegirilgan hisobni yopadi (spiskadagi tovar narxlari o'zgarmaydi).
            if (discount > 0) {
              await salesService.setSaleDiscount(
                saleId: saleId,
                discountAmount: discount,
              );
            }

            // Payments SEQUENTIALLY too — multi-tender (e.g. Cash + Terminal)
            // otherwise hits the single per-market CashRegister row and the
            // per-sale Debt row concurrently → 409.
            // Qarz qoldirilsa — standart to'lov muddati +14 kun (keyin Qarz
            // bo'limidan aniq sanaga o'zgartirsa bo'ladi).
            final dueIso = useDebt
                ? DateTime.now().add(const Duration(days: 14)).toIso8601String()
                : null;
            for (final payment in payments) {
              await salesService.addPayment(
                saleId: saleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
                dueDate: dueIso,
              );
            }

            if (useDebt && payments.isEmpty) {
              await salesService.markSaleAsDebt(saleId, dueDate: dueIso);
            }

            if (!mounted) return;

            setState(() {
              _cartItems.clear();
              _selectedCustomer = null;
            });

            navigator.pop();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(useDebt ? l10n.saleAsDebt : l10n.saleSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            navigator.pop(true);
          } catch (e) {
            // Restore stock for anything already added. Run this BEFORE the
            // mounted check — navigating away mid-failure must not leak stock.
            // _abortSale prefers cancelSale (also drops the empty draft) but
            // falls back to per-item removeSaleItem, which a cashier is
            // authorized for, so a Seller's failed sale no longer silently
            // leaks stock (the old swallowed cancelSale 403) and snowballs into
            // false "omborda yo'q" errors.
            var stockRestored = true;
            if (finalSaleId != null) {
              stockRestored = await _abortSale(
                salesService,
                finalSaleId,
                addedItems,
              );
            }
            if (!mounted) return;
            navigator.pop();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  stockRestored
                      ? '${l10n.error}: $e'
                      : '${l10n.stockRestoreFailedWarning} ($e)',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }

  /// Record a just-added sale item (id -> quantity) so a later failure in the
  /// same checkout/draft can restore its stock. addSaleItem merges duplicate
  /// products into a single row, so we key by id and keep the latest cumulative
  /// quantity (removeSaleItem with that quantity deletes the row and restores
  /// the full stock).
  static void _trackAddedItem(Map<String, double> added, dynamic result) {
    if (result is Map) {
      final id = result['id'];
      final qty = result['quantity'];
      if (id is String && qty is num) added[id] = qty.toDouble();
    }
  }

  /// Undo a partially-created sale after a failure; returns whether stock was
  /// fully restored.
  ///
  /// Prefers cancelSale (which also deletes the now-orphan draft) but that
  /// requires SalesDelete (Owner/Admin only); for a cashier (Seller) it 403s,
  /// so we fall back to removeSaleItem — gated by SalesCreate, which sellers
  /// have — for each item we added. removeSaleItem restores the product's
  /// stock. This replaces the old `try { cancelSale } catch (_) {}` that
  /// silently swallowed the 403 and leaked stock, which over repeated retries
  /// produced false "omborda yetarli mahsulot yo'q" errors.
  Future<bool> _abortSale(
    SalesService salesService,
    String saleId,
    Map<String, double> addedItems,
  ) async {
    try {
      await salesService.cancelSale(saleId: saleId);
      return true;
    } catch (_) {
      // Not authorized to cancel (Seller) or cancel failed — reverse per item.
    }
    var restored = true;
    for (final entry in addedItems.entries) {
      try {
        await salesService.removeSaleItem(
          saleId: saleId,
          saleItemId: entry.key,
          quantity: entry.value,
        );
      } catch (_) {
        restored = false;
      }
    }
    return restored;
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

  /// Persist the current cart as a Draft sale. Returns true on success.
  ///
  /// On a partial failure it rolls back the items it already added (so no orphan
  /// draft is left holding leaked stock) and returns false — the caller then
  /// keeps the user on the screen with their cart intact instead of silently
  /// discarding it. Previously this had NO rollback: a mid-loop failure left a
  /// partial draft whose already-added items held decremented stock.
  Future<bool> _saveAsDraft() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cartItems.isEmpty) {
      return true;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final salesService = SalesService(authProvider: authProvider);
    String? saleId;
    final addedItems = <String, double>{};
    try {
      final sale = await salesService.createSale(
        customerId: _selectedCustomer?['id'],
      );
      saleId = sale['id'] as String;

      for (var item in _cartItems) {
        final dynamic added;
        if (item['isExternal'] == true) {
          // External product draft
          added = await salesService.addSaleItem(
            saleId: saleId,
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
          added = await salesService.addSaleItem(
            saleId: saleId,
            productId: item['productId'],
            quantity: item['quantity'],
            salePrice: item['salePrice'],
            minSalePrice: item['minSalePrice'] ?? 0.0,
            comment: item['comment'],
          );
        }
        _trackAddedItem(addedItems, added);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.draftSaved),
            backgroundColor: context.colors.brand,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      // Roll back the partial draft so it doesn't hold leaked stock.
      if (saleId != null) {
        await _abortSale(salesService, saleId, addedItems);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.draftSaveError}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
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
        backgroundColor: context.colors.surface,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.shopping_cart_checkout_rounded,
                color: context.colors.brand,
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
            color: context.colors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'discard'),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.danger,
            ),
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
              backgroundColor: context.colors.brand,
              foregroundColor: context.colors.onBrand,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );

    if (action == 'save') {
      // Only leave the screen if the draft actually saved. On failure
      // _saveAsDraft rolls back its partial writes and returns false, so we
      // stay put and the cashier keeps the cart instead of losing the sale.
      return await _saveAsDraft();
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
        backgroundColor: context.colors.bg,
        appBar: _buildAppBar(context, l10n),
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
        bottomNavigationBar: _buildCartBar(context, l10n),
      ),
    );
  }

  /// Sticky POS header — back button, title with meta-line, customer chip.
  /// White surface, bottom soft border, matches the demo's `.pos-header`.
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            bottom: BorderSide(color: context.colors.borderSoft, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                PosBackButton(onTap: () => Navigator.maybePop(context)),
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
                          color: context.colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                CustomerChip(
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
  Widget _buildCartBar(BuildContext context, AppLocalizations l10n) {
    final hasItems = _cartItems.isNotEmpty;
    final itemNames = _cartItems
        .take(3)
        .map((e) => (e['productName'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border, width: 2)),
        boxShadow: const [
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
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasItems) ...[
                CartSummaryRow(
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
                    : l10n.processReturn.replaceAll(
                        l10n.returnText,
                        l10n.saleText,
                      ),
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
    showCartSheet(
      context,
      cartItems: _cartItems,
      onUpdateQuantity: _updateQuantity,
      onEditItemPrice: _editItemPrice,
      onRemoveFromCart: _removeFromCart,
      onCheckout: _completeSale,
    );
  }
}
