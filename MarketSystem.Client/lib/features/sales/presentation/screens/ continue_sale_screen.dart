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
import '../../../../core/utils/number_formatter.dart';
import '../../../sales/presentation/widgets/return_quantity_dialog.dart';

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
          : _products.where((p) {
              final name = (p['name'] ?? '').toLowerCase();
              return name.contains(query);
            }).toList();
    });
  }

  double get _totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item['salePrice'] is num
          ? (item['salePrice'] as num).toDouble()
          : double.tryParse(item['salePrice']?.toString() ?? '') ?? 0.0;
      final qty = item['quantity'] is num
          ? (item['quantity'] as num).toDouble()
          : double.tryParse(item['quantity']?.toString() ?? '') ?? 0.0;
      return sum + (price * qty);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final productService = ProductService(authProvider: authProvider);

      final sale = await salesService.getSaleById(widget.saleId);
      final products = await productService.getAllProducts();

      final items = sale['items'] as List<dynamic>? ?? [];
      final cartItems = items.map((item) {
        return {
          'saleItemId': item['id'],
          'productId': item['productId'],
          'productName': item['productName'],
          'salePrice': (item['salePrice'] as num?)?.toDouble() ?? 0.0,
          'minSalePrice': (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          'costPrice': (item['costPrice'] as num?)?.toDouble() ?? 0.0,
          'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
          'comment': item['comment'] ?? '',
        };
      }).toList();

      setState(() {
        _sale = sale;
        _products = products;
        _filteredProducts = products;
        _cartItems = List<Map<String, dynamic>>.from(cartItems);
        _selectedCustomer = sale['customerName'] != null
            ? {'id': sale['customerId'], 'fullName': sale['customerName']}
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addToCart(dynamic product) async {
    final newItem = {
      'productId': product['id'],
      'productName': product['name'],
      'salePrice': product['salePrice'] ?? 0.0,
      'minSalePrice': (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
      'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
      'quantity': 1.0,
      'comment': '',
    };

    setState(() => _cartItems.add(newItem));

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      await salesService.addSaleItem(
        saleId: widget.saleId,
        productId: product['id'],
        quantity: 1.0,
        salePrice: product['salePrice'] ?? 0.0,
        minSalePrice: (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
        comment: '',
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${product['name']} savatga qo\'shildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFromCart(int index) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mahsulot olib tashlandi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cartItems.insert(index, backup));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateQuantity(int index, double newQuantity) async {
    final item = _cartItems[index];

    if (newQuantity <= 0) {
      await _removeFromCart(index);
      return;
    }

    final currentQuantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    if (newQuantity == currentQuantity) return;

    final quantityDiff = newQuantity - currentQuantity;

    if (item.containsKey('saleItemId')) {
      setState(() => _cartItems[index]['quantity'] = newQuantity);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      if (quantityDiff > 0) {
        await salesService.addSaleItem(
          saleId: widget.saleId,
          productId: item['productId'],
          quantity: quantityDiff,
          salePrice: item['salePrice'],
          minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          comment: item['comment'] ?? '',
        );
      } else {
        await salesService.removeSaleItem(
          saleId: widget.saleId,
          saleItemId: item['saleItemId'],
          quantity: quantityDiff.abs(),
        );
      }
      await _loadData();
    } catch (e) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateItemPrice(int index) async {
    final item = _cartItems[index];
    final currentPrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => _PriceInputDialog(
        currentPrice: currentPrice,
        productName: item['productName'],
      ),
    );

    if (!mounted || result == null || result == currentPrice) return;

    if (item.containsKey('saleItemId')) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final salesService = SalesService(authProvider: authProvider);
        await salesService.updateSaleItemPrice(
          saleItemId: item['saleItemId'],
          newPrice: result,
          comment: 'Narx yangilandi (Draft savdo)',
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ Narx yangilandi: ${NumberFormatter.format(result)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _returnItem(int index) async {
    final item = _cartItems[index];
    final currentQuantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    if (currentQuantity <= 0) return;

    final returnQuantity = await showDialog<double>(
      context: context,
      builder: (context) => ReturnQuantityDialog(
        productName: item['productName'],
        maxQuantity: currentQuantity,
      ),
    );

    if (returnQuantity == null || returnQuantity <= 0) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      await salesService.returnSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: returnQuantity,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${item['productName']} qaytarildi: $returnQuantity ${item['unitName'] ?? ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentDialog() {
    final totalAmount = (_sale!['totalAmount'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ContinuePaymentDialog(
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
              Navigator.pop(dialogContext);
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Xatolik: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.draftSales, // Arb faylga qo'shdik: "Draft Savdo"
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sale == null) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.draftSales, // Arb faylga qo'shdik: "Draft Savdo"
        ),
        body: const Center(child: Text('Savdo topilmadi')),
      );
    }

    final customerName = _sale!['customerName'];
    final isClosed = _sale?['status'] == 'Closed';

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: l10n.draftSale,
      ),
      body: Column(
        children: [
          if (customerName != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  Text(
                    customerName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (_cartItems.isNotEmpty)
            Container(
              height: 104,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  return ContinueSaleCartItem(
                    item: _cartItems[index],
                    isClosed: isClosed,
                    onEditPrice: () => _updateItemPrice(index),
                    onReturn: () => _returnItem(index),
                    onDecrement: () async {
                      final qty =
                          (_cartItems[index]['quantity'] as num?)?.toDouble() ?? 0.0;
                      await _updateQuantity(index, qty - 1);
                    },
                    onIncrement: () async {
                      final qty =
                          (_cartItems[index]['quantity'] as num?)?.toDouble() ?? 0.0;
                      await _updateQuantity(index, qty + 1);
                    },
                    onRemove: () => _removeFromCart(index),
                  );
                },
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Mahsulot qidirish...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Color(0xFF9CA3AF)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProducts();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(
                          child: Text('Mahsulotlar topilmadi',
                              style: TextStyle(color: Color(0xFF9CA3AF))))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return ContinueSaleProductCard(
                              product: product,
                              onTap: () => _addToCart(product),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          ContinueSaleBottomBar(
            totalAmount: _totalAmount,
            cartIsEmpty: _cartItems.isEmpty,
            isClosed: isClosed,
            onCheckout: _showPaymentDialog,
          ),
        ],
      ),
    );
  }
}

// Bu faqat ContinueSaleScreen uchun private dialog - alohida chiqarilmaydi
class _PriceInputDialog extends StatefulWidget {
  final double currentPrice;
  final String productName;

  const _PriceInputDialog({
    required this.currentPrice,
    required this.productName,
  });

  @override
  State<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<_PriceInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.currentPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productName),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Yangi narx',
          suffixText: 'so\'m',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: () {
            final price = double.tryParse(_controller.text);
            if (price != null && price > 0) {
              Navigator.pop(context, price);
            }
          },
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}
