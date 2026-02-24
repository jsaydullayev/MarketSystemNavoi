import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/sales_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/number_formatter.dart';
import '../presentation/bloc/sales_bloc.dart';
import '../presentation/bloc/events/sales_event.dart';

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

  // Search & Filter
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

  double get _totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      return sum + (item['salePrice'] * item['quantity']);
    });
  }

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
    // Check if product already in cart
    final existingIndex =
        _cartItems.indexWhere((item) => item['productId'] == product['id']);

    if (existingIndex != -1) {
      // Product exists - increase quantity by 1
      final currentQty = _cartItems[existingIndex]['quantity'] as num? ?? 1.0;
      setState(() {
        _cartItems[existingIndex]['quantity'] = currentQty.toDouble() + 1.0;  // ✅ DECIMAL
      });
    } else {
      // New product - show price input dialog
      _showPriceInputDialog(product);
    }
  }

  void _showPriceInputDialog(dynamic product) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PriceInputDialog(
        product: product,
        onAddToCart: (enteredPrice, enteredQuantity, comment) {  // ✅ 3 parametr
          setState(() {
            _cartItems.add({
              'productId': product['id'],
              'productName': product['name'],
              'salePrice': enteredPrice,
              'minSalePrice': product['minSalePrice'] ?? 0.0,
              'costPrice': product['costPrice'],
              'quantity': enteredQuantity,  // ✅ DECIMAL
              'comment': comment,  // ✅ null check olib tashlandi
            });
          });

          if (mounted) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${product['name']} savatga qo\'shildi!',
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

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, double newQuantity) {  // ✅ DECIMAL
    if (newQuantity <= 0) {
      _removeFromCart(index);
    } else {
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }
  }

  void _editItemPrice(int index, Map<String, dynamic> item) {
    final currentPrice = item['salePrice'] ?? 0.0;
    final currentQuantity = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 1.0;  // ✅ Current quantity
    final minPrice = item['minSalePrice'] ?? 0.0;

    // ✅ Get unit name from products list
    final product = _products.firstWhere(
      (p) => p['id'] == item['productId'],
      orElse: () => {},
    );

    showDialog(
      context: context,
      builder: (dialogContext) => _PriceInputDialog(
        product: {
          'name': item['productName'],
          'salePrice': currentPrice,
          'minSalePrice': minPrice,
          'costPrice': item['costPrice'],
          'id': item['productId'],
          'unitName': product['unitName'] ?? 'dona',
          'initialQuantity': currentQuantity,  // ✅ Joriy miqdorni beramiz
        },
        onAddToCart: (newPrice, newQuantity, comment) {  // ✅ 3 parametr
          setState(() {
            _cartItems[index]['salePrice'] = newPrice;
            _cartItems[index]['quantity'] = newQuantity;  // ✅ Miqdorni ham yangilaymiz
            if (comment != null && comment.isNotEmpty) {
              _cartItems[index]['comment'] = comment;
            }
          });

          if (mounted) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${item['productName']} o\'zgartirildi!',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mijozni tanlang'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _customers.isEmpty
              ? const Center(child: Text('Mijozlar topilmadi'))
              : ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text(customer['fullName'] ?? 'Noma\'lum'),
                      subtitle: Text(customer['phone'] ?? ''),
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(String? saleId) {
    // Agar qarzga sotmoqchi bo'lsa, mijoz majburiy
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentDialog(
        saleId: saleId ?? '', // Empty string agar saleId null bo'lsa
        totalAmount: _totalAmount,
        selectedCustomer: _selectedCustomer,
        onConfirm: (payments, useDebt) async {
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            String finalSaleId;

            // Agar saleId null bo'lsa, savdo yaratamiz
            if (saleId == null || saleId.isEmpty) {
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

              finalSaleId = sale['id'];

              // 3. Clear cart
              setState(() {
                _cartItems.clear();
              });
            } else {
              finalSaleId = saleId;
            }

            // Barcha to'lovlarni yuborish
            for (var payment in payments) {
              await salesService.addPayment(
                saleId: finalSaleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
              );
            }

            // Agar qarzga yozilsa, statusni Debt ga o'tkazish
            if (useDebt && payments.isEmpty) {
              await salesService.markSaleAsDebt(finalSaleId);
            }

            if (mounted) {
              Navigator.pop(context); // Close dialog

              // ✅ Sales listni yangilash
              try {
                if (context.mounted) {
                  context.read<SalesBloc>().add(const GetSalesEvent());
                }
              } catch (e) {
                // SalesBloc topilmasa, xato yuz bermaydi
              }

              await _completeSaleFinish(useDebt);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Xatolik: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () async {
          // Savdo bekor qilindi
          // Agar savdo allaqachon yaratilgan bo'lsa, o'chiramiz
          if (saleId != null && saleId.isNotEmpty) {
            try {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final salesService = SalesService(authProvider: authProvider);

              // Savdani o'chiramiz
              await salesService.deleteSale(saleId: saleId);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Savdo bekor qilindi'),
                    backgroundColor: Colors.grey,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Savdo o\'chirishda xatolik: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
          // Dialogni yopish - PaymentDialog o'zi yopibdi
        },
      ),
    );
  }

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Savat bo\'sh! Avval mahsulot qo\'shing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ⚠️ OLD FLOW: Avval savdo yaratilardi, keyin to'lov dialog
    // NEW FLOW: Avval to'lov dialog, "Tasdiqlash" bosilganda savdo yaratiladi

    // Demak, hozircha NULL yuboramiz, savdo yaratilmaydi
    // "Tasdiqlash" bosilganda savdo yaratiladi
    _showPaymentDialog(null);
  }

  Future<void> _completeSaleFinish(bool useDebt) async {
    // Show success and navigate back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(useDebt
              ? '✅ Sotuv qarzga yozildi!'
              : '✅ Sotuv muvaffaqiyatli yakunlandi!'),
          backgroundColor: useDebt ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Pop back to DraftSalesScreen and refresh it
        Navigator.pop(context, true);
      }
    }
  }

  // Savdoni draft sifatida saqlash
  Future<void> _saveAsDraft() async {
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
          const SnackBar(
            content: Text('✅ Savdo draft sifatida saqlandi!'),
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

    // Agar mahsulotlar bor bo'lsa, draft saqlashni taklif qilamiz
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Savdani saqlash?'),
        content: Text(
          'Savatda ${_cartItems.length} ta mahsulot bor. Draft sifatida saqlashni xohlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false), // Saqlamasdan chiqish
            child: const Text('Yo\'q, chiqib ketish'),
          ),
          TextButton(
            onPressed: () async {
              // Draft sifatida saqlash
              Navigator.pop(context, true);
            },
            child: const Text('Ha, saqlash',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveAsDraft();
    }

    return true; // Har holda chiqib ketamiz
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Yangi sotuv',
              style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Customer & Total Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Customer selection
                        InkWell(
                          onTap: _showCustomerDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: _selectedCustomer != null
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedCustomer != null
                                        ? _selectedCustomer!['fullName'] ??
                                            'Noma\'lum'
                                        : 'Mijozni tanlang',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedCustomer != null
                                          ? Colors.black87
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                if (_selectedCustomer != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      _selectedCustomer!['phone'] ?? '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500),
                                    ),
                                  ),
                                Icon(Icons.chevron_right,
                                    size: 18, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Total amount - Highlighted
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jami summa',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              Text(
                                NumberFormatter.formatDecimal(_totalAmount),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart items
                  if (_cartItems.isNotEmpty)
                    Container(
                      height: 104,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final itemTotal =
                              item['quantity'] * item['salePrice'];

                          // ✅ Get unit name from products list
                          final product = _products.firstWhere(
                            (p) => p['id'] == item['productId'],
                            orElse: () => {},
                          );
                          final unitName = product['unitName'] ?? 'dona';

                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Color(0xFF1F2937),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['quantity']} $unitName x ${NumberFormatter.format(item['salePrice'])}',  // ✅ Unit qo'shildi
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  NumberFormatter.formatDecimal(itemTotal),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _buildSmallButton(
                                          icon: Icons.remove,
                                          onTap: () => _updateQuantity(
                                              index, item['quantity'] - 1),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(
                                            '${item['quantity']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        _buildSmallButton(
                                          icon: Icons.add,
                                          onTap: () => _updateQuantity(
                                              index, item['quantity'] + 1),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => _editItemPrice(index, item),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF10B981),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.edit_rounded,
                                              size: 12,
                                              color: Color(0xFF10B981),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Narx',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeFromCart(index),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Color(0xFFEF4444)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // Products section
                  Expanded(
                    child: Column(
                      children: [
                        // Search bar
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
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
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

                        // Products grid
                        Expanded(
                          child: _filteredProducts.isEmpty
                              ? const Center(
                                  child: Text('Mahsulotlar topilmadi',
                                      style:
                                          TextStyle(color: Color(0xFF9CA3AF))))
                              : GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                                    final quantity = (product['quantity'] as num?)?.toDouble() ?? 0.0;
                                    final isInStock = quantity > 0;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isInStock
                                              ? const Color(0xFFE5E7EB)
                                              : Colors.grey.shade300,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.02),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product['name'] ?? 'Noma\'lum',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: Color(0xFF1F2937),
                                                height: 1.1,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              NumberFormatter.format(
                                                  product['salePrice']),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      size: 10,
                                                      color: quantity > 5
                                                          ? const Color(
                                                              0xFF10B981)
                                                          : const Color(
                                                              0xFFEF4444),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '$quantity',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: quantity > 5
                                                            ? const Color(
                                                                0xFF10B981)
                                                            : const Color(
                                                                0xFFEF4444),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: isInStock
                                                        ? () =>
                                                            _addToCart(product)
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    child: Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        color: isInStock
                                                            ? const Color(
                                                                0xFF3B82F6)
                                                            : Colors
                                                                .grey.shade200,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 14,
                                                          color: isInStock
                                                              ? Colors.white
                                                              : Colors.grey
                                                                  .shade500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Complete sale button
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _completeSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cartItems.isEmpty
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD1D5DB),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 18),
                        label: Text(
                          _isCreating ? 'Sotilmoqda...' : 'SOTISH',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSmallButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF374151)),
      ),
    );
  }
}

// Price Input Dialog Widget
class _PriceInputDialog extends StatefulWidget {
  final dynamic product;
  final Function(double, double, String?) onAddToCart;  // ✅ quantity qo'shildi

  const _PriceInputDialog({
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<_PriceInputDialog> {
  late TextEditingController _priceController;
  late TextEditingController _quantityController;  // ✅ NEW
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    final defaultPrice = widget.product['salePrice'] ?? 0.0;
    _priceController = TextEditingController(
      text: defaultPrice.toStringAsFixed(2),
    );
    final initialQuantity = widget.product['initialQuantity'] ?? 1.0;  // ✅ Joriy miqdor
    _quantityController = TextEditingController(
      text: initialQuantity is double ? initialQuantity.toStringAsFixed(2) : '1',
    );  // ✅ Joriy miqdorni qo'yamiz
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();  // ✅ NEW
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPrice = widget.product['salePrice'] ?? 0.0;
    final minPrice = widget.product['minSalePrice'] ?? 0.0;
    final unitName = widget.product['unitName'] ?? 'dona';  // ✅ NEW

    return AlertDialog(
      title: Text(
        widget.product['name'] ?? 'Mahsulot',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Default price info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Odatiy narx:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    NumberFormatter.format(defaultPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Minimum price warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 20, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimum narx: ${NumberFormatter.format(minPrice)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ✅ NEW: Quantity input field
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),  // ✅ DECIMAL
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Miqdor',
                labelStyle: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF10B981),
                ),
                suffixText: unitName,  // ✅ Unit nomi (dona, kg, m)
                suffixStyle: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD1D5DB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFECFDF5),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            // Price input field
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Sotish narxini kiriting',
                labelStyle: const TextStyle(
                  color: Color(0xFF059669), // Yashil rang
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.sell_rounded,
                  color: Color(0xFF10B981),
                ),
                suffixText: " so'm",
                suffixStyle: const TextStyle(
                  color: Color(0xFF059669), // Yashil rang
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD1D5DB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981), // Yashil border
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981), // Yashil border
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFECFDF5), // Och yashil fon
              ),
              textInputAction: TextInputAction.none, // Keyboardni yopmaydi
              onChanged: (value) {
                setState(() {}); // Rebuild when price changes
              },
            ),
            const SizedBox(height: 12),
            // Optional comment field (always visible but not required)
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                labelStyle: const TextStyle(
                  color: Color(0xFF059669), // Yashil rang
                  fontSize: 13,
                ),
                hintText: 'Necha narxda sotmoqchisiz? (ixtiyoriy)',
                hintStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981), // Yashil border
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981), // Yashil border
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981), // Yashil border
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFECFDF5), // Och yashil fon
                contentPadding: const EdgeInsets.all(12),
              ),
              textInputAction: TextInputAction.newline, // Ko'p qatorli uchun
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Bekor qilish',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final enteredPrice = double.tryParse(_priceController.text) ?? 0.0;
            final enteredQuantity = double.tryParse(_quantityController.text) ?? 1.0;  // ✅ NEW

            if (enteredPrice <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Narx 0 dan katta bo\'lishi kerak!'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (enteredQuantity <= 0) {  // ✅ NEW
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Miqdor 0 dan katta bo\'lishi kerak!'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Allow below minimum - no comment required
            // Just send the price, quantity and optional comment
            // Dialogni onAddToCart ichida yopamiz, shuning uchun bu yerda pop qilmaymiz
            widget.onAddToCart(enteredPrice, enteredQuantity, _commentController.text.trim());  // ✅ quantity qo'shildi
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Savatga qo\'shish',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Payment Dialog Widget
class _PaymentDialog extends StatefulWidget {
  final String saleId; // Nullable, lekin String bo'lishi kerak (empty string allowed)
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;
  final VoidCallback? onCancel;

  const _PaymentDialog({
    super.key,
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useClick = false;
  bool _useDebt = false;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _transferController = TextEditingController();
  final TextEditingController _clickController = TextEditingController();

  bool _isProcessing = false;

  double get _totalPaid {
    double total = 0;
    if (_useCash) total += double.tryParse(_cashController.text) ?? 0;
    if (_useTerminal) total += double.tryParse(_terminalController.text) ?? 0;
    if (_useTransfer) total += double.tryParse(_transferController.text) ?? 0;
    if (_useClick) total += double.tryParse(_clickController.text) ?? 0;
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _totalPaid;

  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  bool _canConfirm() {
    if (_hasDebt) {
      // Qarzga sotish - mijoz bo'lishi shart
      return widget.selectedCustomer != null && _totalPaid >= 0;
    } else {
      // To'liq to'lash kerak
      // Agar to'lov kiritilmagan bo'lsa (0), tasdiqlab bo'lmaydi
      if (_totalPaid <= 0) {
        return false;
      }

      // Qarz tanlanmagan bo'lsa, to'liq to'lash kerak
      if (!_useDebt && _remainingAmount > 0.01) {
        return false;
      }

      return true;
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _terminalController.dispose();
    _transferController.dispose();
    _clickController.dispose();
    super.dispose();
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerDebt =
        (widget.selectedCustomer?['totalDebt'] ?? 0).toDouble();

    return AlertDialog(
      title: const Text('To\'lov usullari'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Naqd
            CheckboxListTile(
              title: const Text('Naqd'),
              subtitle: const Text('Cash',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _useCash,
              onChanged: (value) {
                setState(() {
                  _useCash = value ?? false;
                  if (!_useCash) _cashController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useCash)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Naqd summa (so\'m)',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Terminal
            CheckboxListTile(
              title: const Text('Plastik karta'),
              subtitle: const Text('Terminal',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _useTerminal,
              onChanged: (value) {
                setState(() {
                  _useTerminal = value ?? false;
                  if (!_useTerminal) _terminalController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useTerminal)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _terminalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Plastik summa (so\'m)',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Transfer
            CheckboxListTile(
              title: const Text('Hisob raqam'),
              subtitle: const Text('Transfer',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _useTransfer,
              onChanged: (value) {
                setState(() {
                  _useTransfer = value ?? false;
                  if (!_useTransfer) _transferController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useTransfer)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _transferController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Transfer summa (so\'m)',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Click
            CheckboxListTile(
              title: const Text('Click'),
              subtitle: const Text('Click to\'lov',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _useClick,
              onChanged: (value) {
                setState(() {
                  _useClick = value ?? false;
                  if (!_useClick) _clickController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useClick)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _clickController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Click summa (so\'m)',
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Qarzga (Debt)
            CheckboxListTile(
              title: const Text('Qarzga olish'),
              subtitle: widget.selectedCustomer != null
                  ? Text(
                      '${widget.selectedCustomer!['fullName'] ?? 'Mijoz'} - Hozirgi qarz: ${NumberFormatter.formatDecimal(customerDebt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue))
                  : const Text('Mijoz tanlang',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
              value: _useDebt,
              onChanged: (value) {
                if (widget.selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Qarzga olish uchun avval mijoz tanlang!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                setState(() {
                  _useDebt = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jami summa:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(NumberFormatter.formatDecimal(widget.totalAmount)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To\'langan:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(NumberFormatter.formatDecimal(_totalPaid),
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _hasDebt ? 'Qarzga:' : 'Qolgan:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        NumberFormatter.formatDecimal(_remainingAmount),
                        style: TextStyle(
                          color: _hasDebt
                              ? Colors.orange
                              : (_remainingAmount > 0.01
                                  ? Colors.red
                                  : Colors.green),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_hasDebt)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Yangi qarz:',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange)),
                          Text(
                            '+${NumberFormatter.formatDecimal(_remainingAmount)}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onCancel?.call();
                },
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || !_canConfirm()
              ? null
              : () async {
                  // Validation: Kam summa kiritilsa
                  if (_totalPaid < widget.totalAmount && !_useDebt) {
                    if (!mounted) return;
                    _showWarningDialog(
                      'Kam summa kiritildi!',
                      'Jami summa: ${NumberFormatter.formatDecimal(widget.totalAmount)} so\'m\n'
                      'Siz kiritdingiz: ${NumberFormatter.formatDecimal(_totalPaid)} so\'m\n'
                      'Qolgan: ${NumberFormatter.formatDecimal(_remainingAmount)} so\'m\n\n'
                      'Iltimos, to\'liq summani kiriting yoki "Qarzga yozish"ni tanlang.',
                    );
                    return;
                  }

                  // Validation: Ko'p summa kiritilsa
                  if (_totalPaid > widget.totalAmount + 0.01) {
                    if (!mounted) return;
                    _showWarningDialog(
                      'Ko\'p summa kiritildi!',
                      'Jami summa: ${NumberFormatter.formatDecimal(widget.totalAmount)} so\'m\n'
                      'Siz kiritdingiz: ${NumberFormatter.formatDecimal(_totalPaid)} so\'m\n'
                      'Ortiqcha: ${NumberFormatter.formatDecimal(_totalPaid - widget.totalAmount)} so\'m\n\n'
                      'Iltimos, to\'g\'ri summani kiriting.',
                    );
                    return;
                  }

                  setState(() {
                    _isProcessing = true;
                  });

                  // Create payment list
                  List<Map<String, dynamic>> payments = [];

                  if (_useCash && (_cashController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Cash',
                      'amount': double.tryParse(_cashController.text) ?? 0,
                    });
                  }

                  if (_useTerminal && (_terminalController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Terminal',
                      'amount': double.tryParse(_terminalController.text) ?? 0,
                    });
                  }

                  if (_useTransfer && (_transferController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Transfer',
                      'amount': double.tryParse(_transferController.text) ?? 0,
                    });
                  }

                  if (_useClick && (_clickController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Click',
                      'amount': double.tryParse(_clickController.text) ?? 0,
                    });
                  }

                  try {
                    widget.onConfirm(payments, _hasDebt);
                  } catch (e) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                },
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_hasDebt ? 'Qarzga olish' : 'Tasdiqlash'),
        ),
      ],
    );
  }
}
