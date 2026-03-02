import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/features/sales/presentation/widgets/payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/price_input_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/sale_body.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/customer_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  List<dynamic> _products = [];
  List<dynamic> _customers = [];
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _selectedCustomer;

  bool _isLoading = false;
  bool _isCreating = false;

  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

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

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final name = (product['name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
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
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addToCart(dynamic product) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => PriceInputDialog(
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
      ),
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
    final currentPrice = item['salePrice'] ?? 0.0;
    final currentQuantity = item['quantity'] is num
        ? (item['quantity'] as num).toDouble()
        : 1.0; // ✅ Current quantity
    final minPrice = item['minSalePrice'] ?? 0.0;

    final product = _products.firstWhere(
      (p) => p['id'] == item['productId'],
      orElse: () => {},
    );

    showDialog(
      context: context,
      builder: (dialogContext) => PriceInputDialog(
        product: {
          'name': item['productName'] ?? 'Noma\'lum mahsulot',
          'salePrice': (item['salePrice'] ?? 0.0).toDouble(),
          'minSalePrice': (item['minSalePrice'] ?? 0.0).toDouble(),
          'costPrice': (item['costPrice'] ?? 0.0).toDouble(),
          'id': item['productId'] ?? '',
          // BU YERDA: product o'zgaruvchisi null bo'lsa xato bermasligi uchun:
          'unitName': (item['unitName'] ?? 'dona'),
          'initialQuantity': (currentQuantity ?? 1.0).toDouble(),
        },
        onConfirm: (newPrice, newQuantity, comment) {
          setState(() {
            _cartItems[index]['salePrice'] = newPrice;
            _cartItems[index]['quantity'] =
                newQuantity; // ✅ Miqdorni ham yangilaymiz
            if (comment != null && comment.isNotEmpty) {
              _cartItems[index]['comment'] = comment;
            }
          });

          if (mounted) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${item['productName']} ${l10n.itemUpdated}!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }

  void _showCustomerDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full screen bo'lishi uchun
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7, // Ekran 70% qismi
        decoration: BoxDecoration(
          color: AppColors.getCard(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Tepasidagi chiziqcha (Handle)
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    l10n.selectCustomerTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _customers.isEmpty
                  ? Center(child: Text(l10n.noCustomersFound))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
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
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
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
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      if (phone.isNotEmpty)
                                        Text(
                                          phone,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13),
                                        ),
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

  void _showPaymentDialog(String? saleId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        saleId: saleId ?? '',
        totalAmount: _totalAmount,
        selectedCustomer: _selectedCustomer,
        onConfirm: (payments, useDebt) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            String finalSaleId;

            final sale = await salesService.createSale(
              customerId: _selectedCustomer?['id'],
            );
            finalSaleId = sale['id'];

            for (var item in _cartItems) {
              await salesService.addSaleItem(
                saleId: finalSaleId,
                productId: item['productId'],
                quantity: item['quantity'],
                salePrice: item['salePrice'],
                minSalePrice: item['minSalePrice'] ?? 0.0,
                comment: item['comment'],
              );
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

            try {
              context.read<SalesBloc>().add(const GetSalesEvent());
            } catch (_) {}

            navigator.pop();

            scaffoldMessenger.showSnackBar(SnackBar(
                content: Text(useDebt ? l10n.saleAsDebt : l10n.saleSuccess),
                backgroundColor: Colors.green));

            navigator.pop(true);
          } catch (e) {
            if (!mounted) return;

            navigator.pop();

            scaffoldMessenger.showSnackBar(SnackBar(
                content: Text('Xato: $e'), backgroundColor: Colors.red));
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showPaymentDialog(null);
  }

  // Savdoni draft sifatida saqlash
  Future<void> _saveAsDraft() async {
    final l10n = AppLocalizations.of(context)!;
    if (_cartItems.isEmpty) {
      return; // Bo'sh savdoni saqlash shart emas
    }

    try {
      setState(() {
        _isCreating = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      // 1. Create sale
      final sale = await salesService.createSale(
        customerId: _selectedCustomer?['id'],
      );

      // 2. Add all items to sale
      for (var item in _cartItems) {
        await salesService.addSaleItem(
          saleId: sale['id'],
          productId: item['productId'],
          quantity: item['quantity'],
          salePrice: item['salePrice'],
          minSalePrice: item['minSalePrice'],
          comment: item['comment'],
        );
      }

      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.draftSaved}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft saqlashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Back button bosilganda
  Future<bool> _onWillPop() async {
    // Agar savda bo'sh bo'lsa, shunchaki chiqib ketamiz
    if (_cartItems.isEmpty) {
      return true;
    }
    final l10n = AppLocalizations.of(context)!;

    // Agar mahsulotlar bor bo'lsa, draft saqlashni taklif qilamiz
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveSaleTitle),
        content: Text(l10n.draftSavePrompt(_cartItems.length)),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false), // Saqlamasdan chiqish
            child: Text(l10n.discardSale),
          ),
          TextButton(
            onPressed: () async {
              // Draft sifatida saqlash
              Navigator.pop(context, true);
            },
            child: Text(l10n.saveDraft, style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveAsDraft();
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        backgroundColor: AppColors.getBg(isDark),
        appBar: AppBar(
            backgroundColor: AppColors.getCard(isDark),
            title: Text(l10n.newSale)),
        body: SaleBody(
          isLoading: _isLoading,
          filteredProducts: _filteredProducts,
          cartItems: _cartItems,
          selectedCustomer: _selectedCustomer,
          totalAmount: _totalAmount,
          searchController: _searchController,
          onSelectCustomer: _showCustomerDialog,
          onAddToCart: _addToCart,
          onUpdateQuantity: _updateQuantity,
          onRemoveFromCart: _removeFromCart,
          onEditPrice: _editItemPrice,
        ),
        bottomNavigationBar: _buildBottomAction(isDark, l10n),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: _cartItems.isEmpty ? null : _completeSale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline),
              10.width,
              Text(
                l10n.processReturn.replaceAll(l10n.returnText, l10n.saleText),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
