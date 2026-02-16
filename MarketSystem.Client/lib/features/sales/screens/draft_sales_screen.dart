import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/sales_service.dart';
import '../../../data/services/product_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/number_formatter.dart';

/// Draft Savdolar Screeni
/// Seller o'zining tugatilmagan savdolarini ko'radi va davom ettiradi
class DraftSalesScreen extends StatefulWidget {
  const DraftSalesScreen({super.key});

  @override
  State<DraftSalesScreen> createState() => _DraftSalesScreenState();
}

class _DraftSalesScreenState extends State<DraftSalesScreen> {
  List<dynamic> _draftSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDraftSales();
  }

  Future<void> _loadDraftSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      final drafts = await salesService.getMyDraftSales();

      setState(() {
        _draftSales = drafts;
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

  Future<void> _continueSale(dynamic draftSale) async {
    final saleId = draftSale['id'];

    // Draft savdoni yangi sale screen ochamiz
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContinueSaleScreen(saleId: saleId),
        ),
      );

      // Savdo tugatildi bo'lsa, listni yangilash
      if (result == true) {
        _loadDraftSales();
      }
    }
  }

  void _showDeleteConfirmation(String saleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Savdoni o\'chirish'),
        content: const Text('Haqiqatan ham bu savdoni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Delete sale endpointini backendga qo'shish kerak
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Savdo o\'chirildi'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadDraftSales();
            },
            child: const Text('O\'chirish', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Draft Savdolar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _draftSales.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDraftSales,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _draftSales.length,
                    itemBuilder: (context, index) {
                      final sale = _draftSales[index];
                      return _buildDraftSaleCard(sale);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Draft savdolar yo\'q',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Boshlang\'ich savdolar bu yerda ko\'rsatiladi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftSaleCard(dynamic sale) {
    final items = sale['items'] as List<dynamic>? ?? [];
    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = sale['createdAt'];
    final customerName = sale['customerName'];

    // Format date
    String formattedDate = 'Noma\'lum';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdAt.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                NumberFormatter.formatDecimal(totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Customer
          if (customerName != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Items count
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                '${items.length} ta mahsulot',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              // Continue button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _continueSale(sale),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Davom ettirish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                onPressed: () => _showDeleteConfirmation(sale['id']),
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draft savdoni davom ettirish screeni
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

  // Search & Filter
  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    // _loadData() ni async chaqiramiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
      final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      return sum + (price * qty);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final productService = ProductService(authProvider: authProvider);

      final sale = await salesService.getSaleById(widget.saleId);
      final products = await productService.getAllProducts();

      // Mavjud sale items ni cart ga yuklash
      final items = sale['items'] as List<dynamic>? ?? [];
      final cartItems = items.map((item) {
        return {
          'saleItemId': item['id'],
          'productId': item['productId'],
          'productName': item['productName'],
          'salePrice': (item['salePrice'] as num?)?.toDouble() ?? 0.0,
          'minSalePrice': (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          'costPrice': (item['costPrice'] as num?)?.toDouble() ?? 0.0,
          'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
          'comment': item['comment'] ?? '',
        };
      }).toList();

      setState(() {
        _sale = sale;
        _products = products;
        _filteredProducts = products;
        _cartItems = cartItems;
        _selectedCustomer = sale['customerName'] != null
            ? {
                'id': sale['customerId'],
                'fullName': sale['customerName'],
              }
            : null;
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
        Navigator.pop(context);
      }
    }
  }

  void _addToCart(dynamic product) {
    // Check if product already in cart
    final existingIndex = _cartItems.indexWhere((item) =>
        item['productId'] == product['id'] && !item.containsKey('saleItemId'));

    if (existingIndex != -1) {
      // New product exists in cart - increase quantity
      setState(() {
        _cartItems[existingIndex]['quantity']++;
      });
    } else {
      // Check if it's an existing sale item
      final existingSaleItemIndex = _cartItems.indexWhere((item) =>
          item['productId'] == product['id'] && item.containsKey('saleItemId'));

      if (existingSaleItemIndex != -1) {
        // Existing sale item - increase quantity
        setState(() {
          _cartItems[existingSaleItemIndex]['quantity']++;
        });
      } else {
        // New product - show price input dialog
        _showPriceInputDialog(product, isNew: true);
      }
    }
  }

  void _showPriceInputDialog(dynamic product, {required bool isNew}) {
    final enteredPrice = product['salePrice'] ?? 0.0;

    if (isNew) {
      // Yangi mahsulot qo'shish - backendga yuboramiz
      _addNewProductToSale(product, enteredPrice);
    }
  }

  Future<void> _addNewProductToSale(dynamic product, double salePrice) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      await salesService.addSaleItem(
        saleId: widget.saleId,
        productId: product['id'],
        quantity: 1,
        salePrice: salePrice,
        minSalePrice: (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
        comment: '',
      );

      // Reload data
      _loadData();

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

  Future<void> _removeFromCart(int index) async {
    final item = _cartItems[index];

    // Agar bu mavjud sale item bo'lsa, backenddan o'chiramiz
    if (item.containsKey('saleItemId')) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final salesService = SalesService(authProvider: authProvider);

        await salesService.removeSaleItem(
          saleId: widget.saleId,
          saleItemId: item['saleItemId'],
          quantity: (item['quantity'] as num?)?.toInt() ?? 0, // Butunlay o'chirish
        );

        // Reload data
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xatolik: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Yangi qo'shilgan mahsulot - shunchaki cartdan o'chiramiz
      setState(() {
        _cartItems.removeAt(index);
      });
    }
  }

  void _updateQuantity(int index, int newQuantity) async {
    final item = _cartItems[index];

    if (newQuantity <= 0) {
      await _removeFromCart(index);
      return;
    }

    // Agar bu mavjud sale item bo'lsa
    if (item.containsKey('saleItemId')) {
      final currentQuantity = (item['quantity'] as num?)?.toInt() ?? 0;
      final quantityDiff = newQuantity - currentQuantity;

      if (quantityDiff > 0) {
        // Quantity oshirish - yangi item qo'shamiz
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final salesService = SalesService(authProvider: authProvider);

          await salesService.addSaleItem(
            saleId: widget.saleId,
            productId: item['productId'],
            quantity: quantityDiff,
            salePrice: item['salePrice'],
            minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            comment: item['comment'] ?? '',
          );

          // _loadData ni chaqirmaymiz, chunki u allaqachon backenddan yangi ma'lumot oladi
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
      } else {
        // Quantity kamaytirish - removeSaleItem dan foydalanamiz
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final salesService = SalesService(authProvider: authProvider);

          await salesService.removeSaleItem(
            saleId: widget.saleId,
            saleItemId: item['saleItemId'],
            quantity: -quantityDiff, // Mutlaq qiymat
          );

          // _loadData() ni chaqirmaymiz, chunki backenddan javob keladi
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
      }
    } else {
      // Yangi qo'shilgan mahsulot - shunchaki local quantity ni o'zgartiramiz
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }
  }

  void _showPaymentDialog() {
    final totalAmount = (_sale!['totalAmount'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ContinuePaymentDialog(
        saleId: widget.saleId,
        totalAmount: totalAmount,
        selectedCustomer: _selectedCustomer,
        onConfirm: (payments, useDebt) async {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            for (var payment in payments) {
              await salesService.addPayment(
                saleId: widget.saleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
              );
            }

            if (mounted) {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context, true); // Close sale screen with success
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Savdo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Savdo')),
        body: const Center(child: Text('Savdo topilmadi')),
      );
    }

    final customerName = _sale!['customerName'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Draft Savdo'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Customer info
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                  final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
                  final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                  final itemTotal = price * qty;
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          '${item['quantity']} x ${NumberFormatter.format(item['salePrice'])}',
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _updateQuantity(index, (item['quantity'] as num?)?.toInt() ?? 0 - 1),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Color(0xFF374151)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _updateQuantity(index, (item['quantity'] as num?)?.toInt() ?? 0 + 1),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Color(0xFF374151)),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => _removeFromCart(index),
                              child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
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
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
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
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),

                // Products grid
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('Mahsulotlar topilmadi', style: TextStyle(color: Color(0xFF9CA3AF))))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final quantity = product['quantity'] ?? 0;
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
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      NumberFormatter.format(product['salePrice']),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 10,
                                              color: quantity > 5
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$quantity',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: quantity > 5
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isInStock ? () => _addToCart(product) : null,
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isInStock
                                                    ? const Color(0xFF3B82F6)
                                                    : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.add,
                                                  size: 14,
                                                  color: isInStock ? Colors.white : Colors.grey.shade500,
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

          // Total & Checkout button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              children: [
                // Total amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jami summa',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                      Text(
                        NumberFormatter.formatDecimal(_totalAmount),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF10B981), letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _cartItems.isEmpty ? null : _showPaymentDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cartItems.isEmpty ? const Color(0xFFD1D5DB) : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('TO\'LOV QILISH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Dialog for Continue Sale
class _ContinuePaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;

  const _ContinuePaymentDialog({
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
  });

  @override
  State<_ContinuePaymentDialog> createState() => _ContinuePaymentDialogState();
}

class _ContinuePaymentDialogState extends State<_ContinuePaymentDialog> {
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
      return widget.selectedCustomer != null && _totalPaid >= 0;
    } else {
      return _remainingAmount <= 0.01 || (_remainingAmount > 0.01 && _totalPaid > 0);
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

  @override
  Widget build(BuildContext context) {
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
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Terminal
            CheckboxListTile(
              title: const Text('Plastik karta'),
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
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Transfer
            CheckboxListTile(
              title: const Text('Hisob raqam'),
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
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Click
            CheckboxListTile(
              title: const Text('Click'),
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
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Qarzga
            CheckboxListTile(
              title: const Text('Qarzga olish'),
              value: _useDebt,
              onChanged: (value) {
                if (widget.selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Qarzga olish uchun mijoz tanlang!'),
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
                      const Text('Jami:'),
                      Text(NumberFormatter.formatDecimal(widget.totalAmount)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To\'langan:'),
                      Text(
                        NumberFormatter.formatDecimal(_totalPaid),
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_hasDebt ? 'Qarzga:' : 'Qolgan:'),
                      Text(
                        NumberFormatter.formatDecimal(_remainingAmount),
                        style: TextStyle(
                          color: _hasDebt ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || !_canConfirm()
              ? null
              : () async {
                  setState(() {
                    _isProcessing = true;
                  });

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
