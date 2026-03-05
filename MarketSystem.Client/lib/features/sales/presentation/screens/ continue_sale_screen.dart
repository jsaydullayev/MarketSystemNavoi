import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_payment_dialog.dart';

import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_cart_item.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_product_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_bottom_bar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../sales/presentation/widgets/return_quantity_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/price_input_dialog.dart';

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

  Future<void> _loadData() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
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
          .map<Map<String, dynamic>>((item) => {
                'saleItemId': item['id'],
                'productId': item['productId'],
                'productName': item['productName'],
                'salePrice': (item['salePrice'] as num?)?.toDouble() ?? 0.0,
                'minSalePrice':
                    (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
                'costPrice': (item['costPrice'] as num?)?.toDouble() ?? 0.0,
                'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
                'comment': item['comment'] ?? '',
              })
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
        setState(() => _cartItems.add({
              'productId': product['id'],
              'productName': product['name'],
              'salePrice': price,
              'minSalePrice':
                  (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
              'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
              'quantity': qty,
              'comment': comment ?? '',
            }));

        try {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final salesService = SalesService(authProvider: authProvider);
          await salesService.addSaleItem(
            saleId: widget.saleId,
            productId: product['id'],
            quantity: qty,
            salePrice: price,
            minSalePrice: (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            comment: comment,
          );
          await _loadData();
          if (mounted) {
            _showSnack(l10n.productAddedToCart(product['name']),
                isError: false);
          }
        } catch (e) {
          await _loadData();
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
      await _loadData();
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
        await salesService.addSaleItem(
          saleId: widget.saleId,
          productId: item['productId'],
          quantity: diff,
          salePrice: item['salePrice'],
          minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          comment: item['comment'] ?? '',
        );
      } else {
        await salesService.removeSaleItem(
          saleId: widget.saleId,
          saleItemId: item['saleItemId'],
          quantity: diff.abs(),
        );
      }
      await _loadData();
    } catch (e) {
      await _loadData();
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
            comment == item['comment']) return;

        if (!item.containsKey('saleItemId')) return;

        try {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
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
            await salesService.addSaleItem(
              saleId: widget.saleId,
              productId: item['productId'],
              quantity: diff,
              salePrice: newPrice,
              minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
              comment: comment ?? '',
            );
          } else if (diff < 0) {
            await salesService.removeSaleItem(
              saleId: widget.saleId,
              saleItemId: item['saleItemId'],
              quantity: diff.abs(),
            );
          }

          await _loadData();
          if (mounted) _showSnack(l10n.productUpdated, isError: false);
        } catch (e) {
          await _loadData();
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

    final returnQty = await showDialog<double>(
      context: context,
      builder: (_) => ReturnQuantityDialog(
        productName: item['productName'],
        maxQuantity: currentQty,
      ),
    );

    if (returnQty == null || returnQty <= 0) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      await salesService.returnSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: returnQty,
      );
      await _loadData();
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
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final salesService = SalesService(authProvider: authProvider);
          for (var payment in payments) {
            await salesService.addPayment(
              saleId: widget.saleId,
              paymentType: payment['paymentType'],
              amount: payment['amount'],
            );
          }
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

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(title: l10n.draftSale),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sale == null) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(title: l10n.draftSale),
        body: Center(child: Text(l10n.saleNotFound)),
      );
    }

    final customerName = _sale!['customerName'] as String?;
    final isClosed = _sale?['status'] == 'Closed';

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(title: l10n.draftSale),
      body: Column(
        children: [
          if (customerName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F9FF),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFF3B82F6), size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    customerName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (_cartItems.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) => ContinueSaleCartItem(
                  item: _cartItems[index],
                  isClosed: isClosed,
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
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.searchProduct,
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Color(0xFF9CA3AF)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _filterProducts();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF3B82F6), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(
                                l10n.productsNotFound,
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) =>
                              ContinueSaleProductCard(
                            product: _filteredProducts[index],
                            onTap: () => _addToCart(_filteredProducts[index]),
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
    );
  }
}
