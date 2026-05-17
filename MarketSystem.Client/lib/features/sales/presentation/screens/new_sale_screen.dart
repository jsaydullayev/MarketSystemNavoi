import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/features/sales/presentation/providers/cart_provider.dart';
import 'package:market_system_client/features/sales/presentation/widgets/payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/price_input_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/sale_body.dart';
import 'package:market_system_client/features/sales/presentation/widgets/external_product_sheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../core/providers/auth_provider.dart';

/// Provides [CartProvider] scoped to this screen, then renders [_NewSaleView].
class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return ChangeNotifierProvider(
      create: (_) => CartProvider(authProvider),
      child: const _NewSaleView(),
    );
  }
}

// ---------------------------------------------------------------------------

class _NewSaleView extends StatefulWidget {
  const _NewSaleView();

  @override
  State<_NewSaleView> createState() => _NewSaleViewState();
}

class _NewSaleViewState extends State<_NewSaleView> {
  final _searchController = TextEditingController();
  late final CartProvider _cart;

  @override
  void initState() {
    super.initState();
    _cart = context.read<CartProvider>();
    _cart.loadData();
    _searchController.addListener(
      () => _cart.updateSearchQuery(_searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Cart actions ────────────────────────────────────────────────────────

  void _addToCart(dynamic product) {
    final l10n = AppLocalizations.of(context)!;
    PriceInputSheet.show(
      context,
      product: product,
      onConfirm: (price, qty, comment) {
        _cart.addToCart({
          'productId': product['id'],
          'productName': product['name'],
          'salePrice': price,
          'quantity': qty,
          'comment': comment,
          'minSalePrice': (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
          'unitName': product['unitName'] ?? 'dona',
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${product['name']} ${l10n.returnSuccess}"),
            backgroundColor: AppColors.success,
          ));
        }
      },
    );
  }

  void _addExternalProduct() {
    final l10n = AppLocalizations.of(context)!;
    ExternalProductSheet.show(
      context,
      onConfirm: (name, costPrice, qty, salePrice, comment) {
        _cart.addToCart({
          'isExternal': true,
          'externalCostPrice': costPrice,
          'productId': null,
          'productName': name,
          'salePrice': salePrice,
          'quantity': qty,
          'comment': comment,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$name ${l10n.returnSuccess}'),
            backgroundColor: Colors.orange,
          ));
        }
      },
    );
  }

  void _editItemPrice(int index, Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final currentQuantity =
        item['quantity'] is num ? (item['quantity'] as num).toDouble() : 1.0;

    PriceInputSheet.show(context, product: {
      'name': item['productName'] ?? l10n.unknownProduct,
      'salePrice': (item['salePrice'] ?? 0.0).toDouble(),
      'minSalePrice': (item['minSalePrice'] ?? 0.0).toDouble(),
      'costPrice': (item['costPrice'] ?? 0.0).toDouble(),
      'id': item['productId'] ?? '',
      'unitName': item['unitName'] ?? 'dona',
      'initialQuantity': currentQuantity,
    }, onConfirm: (newPrice, newQuantity, comment) {
      _cart.updateItemPrice(index, newPrice, newQuantity, comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${item['productName']} ${l10n.itemUpdated}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ));
      }
    });
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  void _showCustomerDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customers = _cart.customers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.getCard(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(l10n.selectCustomerTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: customers.isEmpty
                  ? Center(child: Text(l10n.noCustomersFound))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final name = customer['fullName'] ?? l10n.unknown;
                        final phone = customer['phone'] ?? '';
                        final isSelected =
                            _cart.selectedCustomer?['id'] == customer['id'];

                        return InkWell(
                          onTap: () {
                            _cart.selectCustomer(customer);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  child: Text(name[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      if (phone.isNotEmpty)
                                        Text(phone,
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    final l10n = AppLocalizations.of(context)!;
    final cartSnapshot = List<Map<String, dynamic>>.from(_cart.cartItems);
    final customerSnapshot = _cart.selectedCustomer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        saleId: '',
        totalAmount: _cart.totalAmount,
        selectedCustomer: customerSnapshot,
        onConfirm: (payments, useDebt) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            final sale = await salesService.createSale(
              customerId: customerSnapshot?['id'],
            );
            final finalSaleId = sale['id'];

            for (final item in cartSnapshot) {
              if (item['isExternal'] == true) {
                await salesService.addSaleItem(
                  saleId: finalSaleId,
                  isExternal: true,
                  externalProductName: item['productName'],
                  externalCostPrice:
                      (item['externalCostPrice'] as num?)?.toDouble() ?? 0.0,
                  quantity: (item['quantity'] as num).toDouble(),
                  salePrice: (item['salePrice'] as num).toDouble(),
                  minSalePrice: 0.0,
                  comment: item['comment'],
                );
              } else {
                await salesService.addSaleItem(
                  saleId: finalSaleId,
                  productId: item['productId'],
                  quantity: (item['quantity'] as num).toDouble(),
                  salePrice: (item['salePrice'] as num).toDouble(),
                  minSalePrice:
                      (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
                  comment: item['comment'],
                );
              }
            }

            for (final payment in payments) {
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
            _cart.clearCart();

            navigator.pop();
            scaffoldMessenger.showSnackBar(SnackBar(
              content: Text(useDebt ? l10n.saleAsDebt : l10n.saleSuccess),
              backgroundColor: Colors.green,
            ));
            navigator.pop(true);
          } catch (e) {
            if (!mounted) return;
            navigator.pop();
            scaffoldMessenger.showSnackBar(SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: Colors.red,
            ));
          }
        },
      ),
    );
  }

  Future<void> _completeSale() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.cartEmptyWarning),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    _showPaymentDialog();
  }

  /// Returns true when the screen should pop.
  Future<bool> _onWillPop() async {
    if (_cart.isEmpty) return true;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_cart_checkout_rounded,
                  color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.saveSaleTitle,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(
          l10n.draftSavePrompt(_cart.itemCount),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'discard'),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: Color(0xFFEF4444)),
            label: Text(l10n.discardSale,
                style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'save'),
            icon: const Icon(Icons.bookmark_add_rounded, size: 18),
            label: Text(l10n.saveDraft,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF28C33),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (action == 'save') {
      final ok = await _cart.saveAsDraft();
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ ${AppLocalizations.of(context)!.draftSaved}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ));
        } else if (_cart.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.draftSaveError}: ${_cart.errorMessage}'),
            backgroundColor: Colors.red,
          ));
        }
      }
      return ok;
    }
    if (action == 'discard') return true;
    return false; // dismissed — stay on screen
  }

  // ── Cart sheet ───────────────────────────────────────────────────────────

  void _showCartSheet() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.getCard(isDark),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(l10n.cartTitle,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    8.width,
                    Consumer<CartProvider>(
                      builder: (_, cart, __) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${cart.itemCount}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6))),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              // Use Consumer so cart list rebuilds on every change
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (_, cart, __) => cart.isEmpty
                      ? Center(
                          child: Text(l10n.cartEmptyWarning,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13)),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: cart.itemCount,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) => _buildCartSheetItem(
                            index,
                            cart.cartItems[index],
                            isDark,
                            theme,
                            l10n,
                          ),
                        ),
                ),
              ),
              Consumer<CartProvider>(
                builder: (_, cart, __) => _buildCartSheetFooter(
                  isDark,
                  theme,
                  l10n,
                  cart.totalAmount,
                  () {
                    Navigator.pop(ctx);
                    _completeSale();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSheetItem(
    int index,
    Map<String, dynamic> item,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isExternal = item['isExternal'] ?? false;
    final qty = (item['quantity'] as num).toDouble();
    final price = (item['salePrice'] as num).toDouble();
    final subtotal = qty * price;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExternal
            ? Colors.orange.withValues(alpha: 0.06)
            : AppColors.getBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExternal
              ? Colors.orange.withValues(alpha: 0.3)
              : theme.primaryColor.withValues(alpha: 0.2),
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
                      ? Colors.orange.withValues(alpha: 0.15)
                      : theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isExternal
                      ? Icons.add_business_rounded
                      : Icons.inventory_2_rounded,
                  color: isExternal ? Colors.orange : theme.primaryColor,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isExternal ? Colors.orange.shade700 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    2.height,
                    Text(
                      '${qty % 1 == 0 ? qty.toInt() : qty} × ${NumberFormatter.format(price)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormatter.format(subtotal),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981)),
              ),
            ],
          ),
          10.height,
          Row(
            children: [
              _sheetQtyBtn(
                icon: Icons.remove_rounded,
                onTap: () => _cart.updateQuantity(index, qty - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              _sheetQtyBtn(
                icon: Icons.add_rounded,
                onTap: () => _cart.updateQuantity(index, qty + 1),
              ),
              const Spacer(),
              _sheetActionBtn(
                icon: Icons.edit_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _editItemPrice(index, item);
                },
              ),
              8.width,
              _sheetActionBtn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => _cart.removeFromCart(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sheetQtyBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _sheetActionBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildCartSheetFooter(
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
    double totalAmount,
    VoidCallback onCheckout,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        border: Border(
            top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.totalSum,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    NumberFormatter.format(totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            12.height,
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: onCheckout,
              child: Text(l10n.makePayment,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomAction(
      bool isDark, AppLocalizations l10n, CartProvider cart) {
    final theme = Theme.of(context);
    final hasItems = !cart.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCartPreviewChip(isDark, theme, l10n, cart),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: hasItems ? _completeSale : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline),
                  10.width,
                  Text(
                    l10n.processReturn
                        .replaceAll(l10n.returnText, l10n.saleText),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPreviewChip(
      bool isDark, ThemeData theme, AppLocalizations l10n, CartProvider cart) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCartSheet,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    color: Color(0xFF3B82F6), size: 18),
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${cart.itemCount} ${l10n.productsInCartSuffix}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    2.height,
                    Text(l10n.viewEditCart,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Color(0xFF3B82F6)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return PopScope(
      canPop: cart.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(title: l10n.newSale),
        body: SaleBody(
          isLoading: cart.isLoading,
          filteredProducts: cart.filteredProducts,
          cartItems: cart.cartItems,
          selectedCustomer: cart.selectedCustomer,
          totalAmount: cart.totalAmount,
          searchController: _searchController,
          onSelectCustomer: _showCustomerDialog,
          onAddToCart: _addToCart,
          onAddExternalProduct: _addExternalProduct,
          onUpdateQuantity: _cart.updateQuantity,
          onRemoveFromCart: _cart.removeFromCart,
          onEditPrice: _editItemPrice,
          categories: cart.categories,
          selectedCategoryName: cart.selectedCategoryName,
          onCategorySelected: _cart.selectCategory,
        ),
        bottomNavigationBar: _buildBottomAction(isDark, l10n, cart),
      ),
    );
  }
}
