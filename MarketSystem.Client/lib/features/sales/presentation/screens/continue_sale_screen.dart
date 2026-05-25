import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_cart_item.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_product_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_bottom_bar.dart';
import 'package:market_system_client/features/sales/presentation/widgets/customer_selection_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/external_product_sheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../sales/presentation/widgets/return_quantity_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/price_input_dialog.dart';

/// Resume / edit an existing draft sale by `saleId`. Mirrors the new
/// `NewSaleScreen` POS layout: white sticky header (back + title + meta
/// + customer chip), gray search input row, 3-column product grid, and a
/// pinned cart bottom bar. The horizontal "items already added" strip
/// sits between the search and the grid to remind the cashier what's
/// already in this draft.
///
/// Business logic preserved verbatim — every `SalesService` call (sale
/// fetch, add/remove items, update price, return-item, add payment),
/// every snackbar, the role-gated return action, and the silent-refresh
/// flag used to avoid full-screen spinners during in-place edits.
class ContinueSaleScreen extends StatefulWidget {
  final String saleId;

  const ContinueSaleScreen({super.key, required this.saleId});

  @override
  State<ContinueSaleScreen> createState() => _ContinueSaleScreenState();
}

class _ContinueSaleScreenState extends State<ContinueSaleScreen> {
  Map<String, dynamic>? _sale;
  List<Map<String, dynamic>> _cartItems = [];
  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _isLoading = true;

  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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

  double get _totalAmount => _cartItems.fold(0.0, (sum, item) {
    final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    return sum + (price * qty);
  });

  /// Pass `silent: true` for in-place refreshes (after an item add / remove
  /// / edit) so the entire screen doesn't collapse into a CircularProgress
  /// while the API call is in flight. The initial load still shows the
  /// spinner because `_sale` is null at that point and the build method
  /// needs SOMETHING to render.
  Future<void> _loadData({bool silent = false}) async {
    final l10n = AppLocalizations.of(context)!;

    if (!silent) setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final productService = ProductService(authProvider: authProvider);

      final results = await Future.wait([
        salesService.getSaleById(widget.saleId),
        productService.getAllProducts(),
      ]);

      final sale = results[0] as Map<String, dynamic>;
      final products = results[1] as List<dynamic>;
      final items = sale['items'] as List<dynamic>? ?? [];

      final cartItems = items
          .map<Map<String, dynamic>>(
            (item) => {
              'saleItemId': item['id'],
              'productId': item['productId'],
              'productName': item['productName'],
              'salePrice': (item['salePrice'] as num?)?.toDouble() ?? 0.0,
              'minSalePrice': (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
              'costPrice': (item['costPrice'] as num?)?.toDouble() ?? 0.0,
              'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
              'comment': item['comment'] ?? '',
              // External-product fields — without these, _updateQuantity
              // can't tell an external item apart from an ordinary one
              // and would call addSaleItem with productId=null → 400.
              'isExternal': item['isExternal'] == true,
              'externalProductName': item['externalProductName'],
              'externalCostPrice': (item['externalCostPrice'] as num?)
                  ?.toDouble(),
            },
          )
          .toList();

      setState(() {
        _sale = sale;
        _products = products;
        _filteredProducts = products;
        _cartItems = cartItems;
        _selectedCustomer = sale['customerName'] != null
            ? {'id': sale['customerId'], 'fullName': sale['customerName']}
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack('${l10n.error}: $e', isError: true);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addToCart(dynamic product) async {
    final l10n = AppLocalizations.of(context)!;

    PriceInputSheet.show(
      context,
      product: product,
      onConfirm: (price, qty, comment) async {
        setState(
          () => _cartItems.add({
            'productId': product['id'],
            'productName': product['name'],
            'salePrice': price,
            'minSalePrice':
                (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
            'quantity': qty,
            'comment': comment ?? '',
          }),
        );

        try {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final salesService = SalesService(authProvider: authProvider);
          await salesService.addSaleItem(
            saleId: widget.saleId,
            productId: product['id'],
            quantity: qty,
            salePrice: price,
            minSalePrice: (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            comment: comment,
          );
          await _loadData(silent: true);
          if (mounted) {
            _showSnack(
              l10n.productAddedToCart(product['name']),
              isError: false,
            );
          }
        } catch (e) {
          await _loadData(silent: true); // keep the screen on-screen
          // ignore: empty_catches — fall through to snack below
          if (mounted) _showSnack('${l10n.error}: $e', isError: true);
        }
      },
    );
  }

  Future<void> _removeFromCart(int index) async {
    final l10n = AppLocalizations.of(context)!;

    final item = _cartItems[index];
    final backup = Map<String, dynamic>.from(item);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      await salesService.removeSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
      );
      await _loadData(silent: true);
      if (mounted) _showSnack(l10n.productRemoved, isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cartItems.insert(index, backup));
      _showSnack('${l10n.error}: $e', isError: true);
    }
  }

  Future<void> _updateQuantity(int index, double newQty) async {
    final l10n = AppLocalizations.of(context)!;

    final item = _cartItems[index];
    if (newQty <= 0) return _removeFromCart(index);

    final currentQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    if (newQty == currentQty) return;

    final diff = newQty - currentQty;
    if (item.containsKey('saleItemId')) {
      setState(() => _cartItems[index]['quantity'] = newQty);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      if (diff > 0) {
        // Branch on isExternal so external items (productId=null,
        // externalProductName=...) don't get rejected by the backend's
        // "ProductId kerak" guard.
        final isExternal = item['isExternal'] == true;
        if (isExternal) {
          await salesService.addSaleItem(
            saleId: widget.saleId,
            isExternal: true,
            externalProductName:
                (item['externalProductName'] as String?) ??
                (item['productName'] as String?) ??
                '',
            externalCostPrice:
                (item['externalCostPrice'] as num?)?.toDouble() ?? 0.0,
            quantity: diff,
            salePrice: item['salePrice'],
            minSalePrice: 0.0,
            comment: item['comment'] ?? '',
          );
        } else {
          await salesService.addSaleItem(
            saleId: widget.saleId,
            productId: item['productId'],
            quantity: diff,
            salePrice: item['salePrice'],
            minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            comment: item['comment'] ?? '',
          );
        }
      } else {
        await salesService.removeSaleItem(
          saleId: widget.saleId,
          saleItemId: item['saleItemId'],
          quantity: diff.abs(),
        );
      }
      await _loadData(silent: true);
    } catch (e) {
      await _loadData(silent: true);
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    }
  }

  Future<void> _updateItemPrice(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final item = _cartItems[index];
    final currentPrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final currentQty = (item['quantity'] as num?)?.toDouble() ?? 1.0;

    PriceInputSheet.show(
      context,
      product: {
        'name': item['productName'] ?? l10n.unknown,
        'salePrice': currentPrice,
        'minSalePrice': (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
        'costPrice': (item['costPrice'] as num?)?.toDouble() ?? 0.0,
        'id': item['productId'] ?? '',
        'unitName': item['unitName'] ?? l10n.piece,
        'initialQuantity': currentQty,
        'comment': item['comment'] ?? '',
      },
      onConfirm: (newPrice, newQty, comment) async {
        if (!mounted) return;
        if (newPrice == currentPrice &&
            newQty == currentQty &&
            comment == item['comment']) {
          return;
        }

        if (!item.containsKey('saleItemId')) return;

        try {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final salesService = SalesService(authProvider: authProvider);
          final diff = newQty - currentQty;

          if (newPrice != currentPrice || comment != item['comment']) {
            await salesService.updateSaleItemPrice(
              saleItemId: item['saleItemId'],
              newPrice: newPrice,
              comment: comment ?? l10n.priceUpdated,
            );
          }

          if (diff > 0) {
            // Same external/ordinary branch as in _updateQuantity — the
            // backend rejects productId=null for non-external items.
            final isExternal = item['isExternal'] == true;
            if (isExternal) {
              await salesService.addSaleItem(
                saleId: widget.saleId,
                isExternal: true,
                externalProductName:
                    (item['externalProductName'] as String?) ??
                    (item['productName'] as String?) ??
                    '',
                externalCostPrice:
                    (item['externalCostPrice'] as num?)?.toDouble() ?? 0.0,
                quantity: diff,
                salePrice: newPrice,
                minSalePrice: 0.0,
                comment: comment ?? '',
              );
            } else {
              await salesService.addSaleItem(
                saleId: widget.saleId,
                productId: item['productId'],
                quantity: diff,
                salePrice: newPrice,
                minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
                comment: comment ?? '',
              );
            }
          } else if (diff < 0) {
            await salesService.removeSaleItem(
              saleId: widget.saleId,
              saleItemId: item['saleItemId'],
              quantity: diff.abs(),
            );
          }

          await _loadData(silent: true);
          if (mounted) _showSnack(l10n.productUpdated, isError: false);
        } catch (e) {
          await _loadData(silent: true);
          if (mounted) _showSnack('${l10n.error}: $e', isError: true);
        }
      },
    );
  }

  Future<void> _returnItem(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final item = _cartItems[index];
    final currentQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    if (currentQty <= 0) return;

    // Resolve the provider BEFORE the await — reading it from `context`
    // after the dialog closes is the use-build-context-synchronously lint
    // (the widget may have been disposed while the dialog was open).
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final returnQty = await showDialog<double>(
      context: context,
      builder: (_) => ReturnQuantityDialog(
        productName: item['productName'],
        maxQuantity: currentQty,
      ),
    );

    if (returnQty == null || returnQty <= 0) return;

    try {
      final salesService = SalesService(authProvider: authProvider);
      await salesService.returnSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: returnQty,
      );
      await _loadData(silent: true);
      if (mounted) _showSnack(l10n.productReturned, isError: false);
    } catch (e) {
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    }
  }

  void _showPaymentSheet() {
    final l10n = AppLocalizations.of(context)!;
    final totalAmount = (_sale!['totalAmount'] as num?)?.toDouble() ?? 0.0;

    showContinuePaymentSheet(
      context,
      saleId: widget.saleId,
      totalAmount: totalAmount,
      selectedCustomer: _selectedCustomer,
      onConfirm: (payments, useDebt) async {
        try {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final salesService = SalesService(authProvider: authProvider);
          await Future.wait(
            payments.map(
              (payment) => salesService.addPayment(
                saleId: widget.saleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
              ),
            ),
          );
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) _showSnack('${l10n.error}: $e', isError: true);
        }
      },
    );
  }

  /// Add an external (one-off) product to this in-flight sale. Same UX as
  /// in NewSaleScreen but here the item must go straight to the API since
  /// the sale already exists on the server; we don't keep a local-only
  /// cart in Continue mode.
  Future<void> _addExternalProduct() async {
    final l10n = AppLocalizations.of(context)!;
    ExternalProductSheet.show(
      context,
      onConfirm: (name, costPrice, qty, salePrice, comment) async {
        try {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final salesService = SalesService(authProvider: authProvider);
          await salesService.addSaleItem(
            saleId: widget.saleId,
            isExternal: true,
            externalProductName: name,
            externalCostPrice: costPrice,
            quantity: qty,
            salePrice: salePrice,
            minSalePrice: 0.0,
            comment: comment,
          );
          await _loadData(silent: true);
          if (mounted) {
            _showSnack(l10n.productAddedToCart(name), isError: false);
          }
        } catch (e) {
          if (mounted) _showSnack('${l10n.error}: $e', isError: true);
        }
      },
    );
  }

  /// Open the customer-picker dialog. The dialog itself calls
  /// `updateSaleCustomer` on the API; we just refresh after it closes.
  void _selectOrChangeCustomer() {
    showDialog(
      context: context,
      builder: (_) => CustomerSelectionDialog(
        saleId: widget.saleId,
        onCustomerSelected: () => _loadData(silent: true),
      ),
    );
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _sale == null) {
      return NetworkWrapper(
        onRetry: _loadData,
        child: Scaffold(
          backgroundColor: context.colors.bg,
          appBar: _buildAppBar(context, l10n),
          body: Center(
            child: CircularProgressIndicator(color: context.colors.brand),
          ),
        ),
      );
    }

    final isClosed = _sale?['status'] == 'Closed';

    // G3 — backend S2: UpdateSaleItemPriceAsync now refuses anything that
    // isn't Draft or Debt. Mirror the gate so the pencil-edit chip on
    // each cart item only shows in those two states. (`isClosed` is a
    // narrower check — it doesn't cover Paid / Cancelled, both of which
    // the backend now rejects.)
    final status = _sale?['status'] as String?;
    final canEditPrice = status == 'Draft' || status == 'Debt';
    final canReturn = Provider.of<AuthProvider>(context, listen: false).can('sales.edit');

    return NetworkWrapper(
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: _buildAppBar(context, l10n),
        body: Column(
          children: [
            if (_cartItems.isNotEmpty)
              SizedBox(
                height: 118,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) => ContinueSaleCartItem(
                    item: _cartItems[index],
                    isClosed: isClosed,
                    canEditPrice: canEditPrice,
                    canReturn: canReturn,
                    onEditPrice: () => _updateItemPrice(index),
                    onReturn: () => _returnItem(index),
                    onDecrement: () async {
                      final qty =
                          (_cartItems[index]['quantity'] as num?)?.toDouble() ??
                          0.0;
                      await _updateQuantity(index, qty - 1);
                    },
                    onIncrement: () async {
                      final qty =
                          (_cartItems[index]['quantity'] as num?)?.toDouble() ??
                          0.0;
                      await _updateQuantity(index, qty + 1);
                    },
                    onRemove: () => _removeFromCart(index),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchInput(context, l10n)),
                        if (!isClosed) ...[
                          const SizedBox(width: AppSpacing.md),
                          _ExternalProductButton(
                            tooltip: l10n.addExternalProduct,
                            onTap: _addExternalProduct,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? _buildEmptyState(context, l10n)
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.xs,
                              AppSpacing.xl,
                              AppSpacing.md,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.45,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) =>
                                ContinueSaleProductCard(
                                  product: _filteredProducts[index],
                                  onTap: () =>
                                      _addToCart(_filteredProducts[index]),
                                ),
                          ),
                  ),
                ],
              ),
            ),
            ContinueSaleBottomBar(
              totalAmount: _totalAmount,
              cartIsEmpty: _cartItems.isEmpty,
              isClosed: isClosed,
              onCheckout: _showPaymentSheet,
            ),
          ],
        ),
      ),
    );
  }

  /// Custom POS-style header — back button + title with chek# meta on the
  /// left, customer chip on the right. Mirrors `NewSaleScreen` so the
  /// "continue" experience visually picks up where "new" left off.
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
                _PosBackButton(onTap: () => Navigator.maybePop(context)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.draftSale,
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
                _CustomerChip(
                  customer: _selectedCustomer,
                  fallbackLabel: l10n.customerNotSelected,
                  enabled: _sale == null ? false : _sale?['status'] != 'Closed',
                  onTap: _selectOrChangeCustomer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Meta line under the title — receipt number from the sale + a stable
  /// time slug. Receipt number falls back to the saleId prefix when the
  /// API hasn't surfaced one.
  String _headerMeta() {
    final receipt = (_sale?['receiptNumber'] ?? _sale?['number'] ?? '')
        .toString();
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (receipt.isNotEmpty) return 'Chek #$receipt · $hh:$mm';
    return 'Chek · $hh:$mm';
  }

  /// Gray-fill search input with brand-orange focus. Replaces the inline
  /// dark-mode-aware TextField from the legacy implementation.
  Widget _buildSearchInput(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: l10n.searchProduct,
        hintStyle: AppTextStyles.bodyMedium().copyWith(
          color: context.colors.textMuted,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: context.colors.textMuted,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                color: context.colors.textSecondary,
                onPressed: () {
                  _searchController.clear();
                  _filterProducts();
                },
              )
            : null,
        filled: true,
        fillColor: context.colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          borderSide: BorderSide(color: context.colors.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: context.colors.border,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.productsNotFound,
            style: AppTextStyles.bodySmall().copyWith(
              color: context.colors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round 36×36 back button — matches the demo's `.pos-back` element.
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
            color: context.colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: context.colors.text,
          ),
        ),
      ),
    );
  }
}

/// Customer chip — pill on the right of the header. Brand-tinted when a
/// customer is selected, neutral grey otherwise. Closed sales disable
/// tapping (the API rejects customer updates on closed sales).
class _CustomerChip extends StatelessWidget {
  const _CustomerChip({
    required this.customer,
    required this.fallbackLabel,
    required this.enabled,
    required this.onTap,
  });

  final Map<String, dynamic>? customer;
  final String fallbackLabel;
  final bool enabled;
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
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: hasCustomer
                  ? context.colors.brandLight
                  : context.colors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasCustomer)
                  _InitialAvatar(name: name)
                else
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: context.colors.textSecondary,
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
                      fontWeight: FontWeight.w700,
                      color: hasCustomer
                          ? context.colors.brand
                          : context.colors.textSecondary,
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

/// 18×18 orange-filled circle with the customer's first initial. Mirrors
/// the avatar used in the `NewSaleScreen` header for visual continuity.
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
      decoration: BoxDecoration(
        color: context.colors.brand,
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

/// 44×44 brand-orange tile that opens the external-product sheet. Replaces
/// the legacy gradient + custom shadow with the design-system brand color.
class _ExternalProductButton extends StatelessWidget {
  const _ExternalProductButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.brand,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              boxShadow: [
                BoxShadow(
                  color: context.colors.brand.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
