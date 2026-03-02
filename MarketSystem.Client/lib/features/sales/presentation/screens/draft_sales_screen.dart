import 'package:flutter/material.dart';
import 'package:market_system_client/features/sales/presentation/widgets/draft_sale_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/return_quantity_dialog.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../core/providers/auth_provider.dart';

/// Draft Savdolar Screeni
/// Seller o'zining tugatilmagan savdolarini ko'radi va davom ettiradi
class DraftSalesScreen extends StatefulWidget {
  const DraftSalesScreen({super.key});

  @override
  State<DraftSalesScreen> createState() => _DraftSalesScreenState();
}

class _DraftSalesScreenState extends State<DraftSalesScreen> {
  List<dynamic> _unfinishedSales = [];
  List<dynamic> _debtors = [];
  bool _isLoading = true;

  // Guruhlangan savdolar
  List<dynamic> get _draftSales =>
      _unfinishedSales.where((s) => s['status'] == 'Draft').toList();
  List<dynamic> get _debtSales =>
      _unfinishedSales.where((s) => s['status'] == 'Debt').toList();
  List<dynamic> get _paidSales =>
      _unfinishedSales.where((s) => s['status'] == 'Paid').toList();

  @override
  void initState() {
    super.initState();
    _loadDraftSales();
    _loadDebtors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      Future.delayed(Duration.zero, () {
        _loadDraftSales();
        _loadDebtors();
      });
    }
  }

  Future<void> _loadDraftSales() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final unfinished = await salesService.getMyUnfinishedSales();
      setState(() {
        _unfinishedSales = unfinished;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadDebtors() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final debtors = await salesService.getDebtors();
      if (mounted) setState(() => _debtors = debtors);
    } catch (e) {
      debugPrint('Error loading debtors: $e');
    }
  }

  Future<void> _continueSale(dynamic draftSale) async {
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContinueSaleScreen(saleId: draftSale['id']),
      ),
    );
    if (result == true) _loadDraftSales();
  }

  void _confirmDelete(String saleId) {
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
              try {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final salesService = SalesService(authProvider: authProvider);
                await salesService.deleteSale(saleId: saleId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Savdo o\'chirildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDraftSales();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Savdoni o\'chirishda xatolik: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child:
                const Text('O\'chirish', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(dynamic sale) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomerSelectionDialog(
        saleId: sale['id'],
        onCustomerSelected: () {
          _loadDraftSales();
        },
      ),
    );
  }

  void _openEditDialog(dynamic sale) {
    _continueSale(sale);
  }

  void _confirmDelete(String saleId) {
    _showDeleteConfirmation(saleId);
  }

  Widget _buildDraftSaleCard(dynamic sale) {
    return DraftSaleCard(
      sale: sale,
      onEdit: () => _openEditDialog(sale),
      onDelete: () => _confirmDelete(sale['id']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Davom etayotgan savdolar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadDraftSales();
                await _loadDebtors();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Qarzdor mijozlar
                  if (_debtors.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Qarzdor mijozlar',
                        icon: Icons.person_outline,
                        color: Colors.red,
                        count: _debtors.length),
                    const SizedBox(height: 8),
                    ..._debtors.map((debtor) => DebtorCard(
                          debtor: debtor,
                          onPaymentTap: () => _showDebtorPayment(debtor),
                          onHistoryTap: () => _showPaymentHistory(debtor),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Davom etayotgan savdolar (Draft)
                  if (_draftSales.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Davom etayotgan',
                        icon: Icons.edit_note,
                        color: Colors.orange,
                        count: _draftSales.length),
                    const SizedBox(height: 8),
                    ..._draftSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Qarz savdolar (Debt)
                  if (_debtSales.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Qarz savdolar',
                        icon: Icons.money_off,
                        color: Colors.red,
                        count: _debtSales.length),
                    const SizedBox(height: 8),
                    ..._debtSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                  ],

                  // To'langan savdolar (Paid)
                  if (_paidSales.isNotEmpty) ...[
                    SectionHeader(
                        title: 'To\'langan savdolar',
                        icon: Icons.assignment_turned_in,
                        color: Colors.green,
                        count: _paidSales.length),
                    const SizedBox(height: 8),
                    ..._paidSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                  ],

                  // Bo'sh holat
                  if (_draftSales.isEmpty &&
                      _debtSales.isEmpty &&
                      _paidSales.isEmpty &&
                      _debtors.isEmpty)
                    const EmptyState(),
                ],
              ),
            ),
    );
  }

  void _showDebtorPayment(dynamic debtor) {
    showDialog(
      context: context,
      builder: (dialogContext) => DebtorPaymentDialog(
        debtor: debtor,
        debtSales: _debtSales,
        onPaymentSuccess: () {
          _loadDraftSales();
          _loadDebtors();
        },
      ),
    );
  }

  void _showPaymentHistory(dynamic debtor) async {
    await _loadDraftSales();
    final customerId = debtor['customerId'];
    final debtorSales =
        _debtSales.where((sale) => sale['customerId'] == customerId).toList();

    if (debtorSales.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qarz savdolari topilmadi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => PaymentHistoryDialog(
        customerName: debtor['customerName'] ?? 'Mijozsiz',
        debtorSales: debtorSales,
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
      final price = item['salePrice'] is num
          ? (item['salePrice'] as num).toDouble()
          : double.tryParse(item['salePrice']?.toString() ?? '') ?? 0.0;
      final qty = item['quantity'] is num
          ? (item['quantity'] as num).toDouble() // ✅ DECIMAL
          : double.tryParse(item['quantity']?.toString() ?? '') ??
              0.0; // ✅ DECIMAL
      return sum + (price * qty);
    });
  }

  Future<void> _loadData() async {
    print('📥 === _loadData START ===');
    print('Sale ID: ${widget.saleId}');

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final productService = ProductService(authProvider: authProvider);

      print('📤 Fetching sale data...');
      final sale = await salesService.getSaleById(widget.saleId);

      print('📤 Fetching products...');
      final products = await productService.getAllProducts();

      // Mavjud sale items ni cart ga yuklash
      final items = sale['items'] as List<dynamic>? ?? [];
      print('📦 Sale items count: ${items.length}');

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

      print('✅ Data fetched successfully!');
      print('📊 Cart items: ${cartItems.length}');

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

      print('✅ setState complete!');
    } catch (e) {
      print('❌ ERROR in _loadData: $e');
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
    print('📥 === _loadData END ===');
  }

  Future<void> _addToCart(dynamic product) async {
    print('🛒 === _addToCart START ===');
    print('Product: ${product['name']}');
    print('Sale ID: ${widget.saleId}');

    // ⚡ OPTIMISTIK UI - Yangi mahsulotni cartga qo'shamiz
    final newItem = {
      'productId': product['id'],
      'productName': product['name'],
      'salePrice': product['salePrice'] ?? 0.0,
      'minSalePrice': (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
      'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
      'quantity': 1,
      'comment': '',
      // saleItemId yo'q - hali backendda yo'q
    };

    print('⚡ Optimistic UI: Adding to cart locally');
    if (!mounted) return;
    setState(() {
      _cartItems.add(newItem);
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      print('📤 Calling addSaleItem...');

      // Backendga 1 ta mahsulot qo'shamiz
      // Backend avtomatik ravishda mavjud itemni topib quantity oshiradi
      await salesService.addSaleItem(
        saleId: widget.saleId,
        productId: product['id'],
        quantity: 1,
        salePrice: product['salePrice'] ?? 0.0,
        minSalePrice: (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
        comment: '',
      );

      print('✅ addSaleItem success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');

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
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, data ni qayta yuklash
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🛒 === _addToCart END ===');
  }

  Future<void> _removeFromCart(int index) async {
    final item = _cartItems[index];

    print('🗑️ === _removeFromCart START ===');
    print('Index: $index');
    print('Product: ${item['productName']}');
    print('SaleItemId: ${item['saleItemId']}');
    print('Quantity: ${item['quantity']}');

    // Itemni backup qilamiz (xatolik bo'lsa, qayta qo'shish uchun)
    final backupItem = Map<String, dynamic>.from(item);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      print('📤 Calling removeSaleItem...');

      // Backenddan o'chiramiz
      await salesService.removeSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: (item['quantity'] as num?)?.toDouble() ??
            0.0, // ✅ DECIMAL - Butunlay o'chirish
      );

      print('✅ removeSaleItem success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mahsulot olib tashlandi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, itemni qayta qo'shamiz
      if (!mounted) return;
      setState(() {
        _cartItems.insert(index, backupItem);
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
    print('🗑️ === _removeFromCart END ===');
  }

  Future<void> _updateQuantity(int index, double newQuantity) async {
    // ✅ DECIMAL
    final item = _cartItems[index];

    print('🔢 === _updateQuantity START ===');
    print('Index: $index');
    print('Product: ${item['productName']}');
    print('Current: ${item['quantity']} → New: $newQuantity');

    if (newQuantity <= 0) {
      print('⚠️ Quantity <= 0, removing...');
      await _removeFromCart(index);
      return;
    }

    final currentQuantity =
        (item['quantity'] as num?)?.toDouble() ?? 0.0; // ✅ DECIMAL

    // quantityDiff == 0 bo'lsa, hech narsa qilmaymiz (quantity o'zgarmagan)
    if (newQuantity == currentQuantity) {
      print('⚠️ Quantity unchanged, skipping');
      return;
    }

    final quantityDiff = newQuantity - currentQuantity;
    print('Diff: $quantityDiff');

    // ⚡ OPTIMISTIK UI YANGILASH - Darhol UI ni yangilaymiz!
    if (item.containsKey('saleItemId')) {
      print('⚡ Optimistic UI update: ${item['quantity']} → $newQuantity');
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      if (quantityDiff > 0) {
        print('📤 INCREASING by $quantityDiff');
        // Quantity oshirish - backendga yangi item qo'shamiz
        await salesService.addSaleItem(
          saleId: widget.saleId,
          productId: item['productId'],
          quantity: quantityDiff, // ✅ DECIMAL
          salePrice: item['salePrice'],
          minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          comment: item['comment'] ?? '',
        );
      } else {
        print('📤 DECREASING by ${quantityDiff.abs()}');
        // Quantity kamaytirish - backenddan removeSaleItem orqali kamaytiramiz
        final quantityToRemove = quantityDiff.abs(); // ✅ DECIMAL
        await salesService.removeSaleItem(
          saleId: widget.saleId,
          saleItemId: item['saleItemId'],
          quantity: quantityToRemove, // ✅ DECIMAL
        );
      }

      print('✅ API call success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, data ni qayta yuklash
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🔢 === _updateQuantity END ===');
  }

  Future<void> _updateItemPrice(int index) async {
    final item = _cartItems[index];
    final currentPrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;

    // Narx kiritish dialogi
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _PriceInputDialog(
        currentPrice: currentPrice,
        productName: item['productName'],
      ),
    );

    if (!mounted) return;

    if (result != null && result != currentPrice) {
      // Narxni o'zgartirish
      if (item.containsKey('saleItemId')) {
        try {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final salesService = SalesService(authProvider: authProvider);

          await salesService.updateSaleItemPrice(
            saleItemId: item['saleItemId'],
            newPrice: result,
            comment: 'Narx yangilandi (Draft savdo)',
          );

          // Reload data
          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Narx yangilandi: ${NumberFormatter.format(result)}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
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

  Future<void> _returnItem(int index) async {
    final item = _cartItems[index];
    final currentQuantity =
        (item['quantity'] as num?)?.toDouble() ?? 0.0; // ✅ DECIMAL

    print('↩️ === _returnItem START ===');
    print('Index: $index');
    print('Product: ${item['productName']}');
    print('Current Quantity: $currentQuantity');

    if (currentQuantity <= 0) {
      print('⚠️ Quantity is 0, cannot return');
      return;
    }

    // Qancha qaytarishni so'rash
    final returnQuantity = await showDialog<double>(
      // ✅ DECIMAL
      context: context,
      builder: (context) => ReturnQuantityDialog(
        productName: item['productName'],
        maxQuantity: currentQuantity, // ✅ DECIMAL
      ),
    );

    if (returnQuantity == null || returnQuantity <= 0) {
      print('⚠️ Return cancelled or invalid quantity');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      print('📤 Calling returnSaleItem...');
      print('Sale Item ID: ${item['saleItemId']}');
      print('Return Quantity: $returnQuantity');

      await salesService.returnSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: returnQuantity.toDouble(),
      );

      print('✅ returnSaleItem success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${returnQuantity} ta ${item['productName']} qaytarildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, data ni qayta yuklash
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('↩️ === _returnItem END ===');
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
                        Row(
                          children: [
                            Text(
                              NumberFormatter.formatDecimal(itemTotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _updateItemPrice(index),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Agar savdo yopilgan (Closed) bo'lsa, vozvrat tugmasi
                            if (_sale?['status'] == 'Closed')
                              GestureDetector(
                                onTap: () => _returnItem(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.orange.shade300,
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.assignment_return,
                                          size: 14,
                                          color: Colors.orange.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qaytarish',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final currentQty =
                                          (item['quantity'] as num?)?.toInt() ??
                                              0;
                                      await _updateQuantity(
                                          index, currentQty - 1);
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.remove,
                                          size: 14, color: Color(0xFF374151)),
                                    ),
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
                                  GestureDetector(
                                    onTap: () async {
                                      final currentQty =
                                          (item['quantity'] as num?)?.toInt() ??
                                              0;
                                      await _updateQuantity(
                                          index, currentQty + 1);
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.add,
                                          size: 14, color: Color(0xFF374151)),
                                    ),
                                  ),
                                ],
                              ),
                            if (_sale?['status'] != 'Closed')
                              GestureDetector(
                                onTap: () async {
                                  await _removeFromCart(index);
                                },
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

                // Products grid
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
                            final quantity =
                                (product['quantity'] as num?)?.toDouble() ??
                                    0.0;
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
                                          MainAxisAlignment.spaceBetween,
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
                                            onTap: isInStock
                                                ? () async {
                                                    await _addToCart(product);
                                                  }
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isInStock
                                                    ? const Color(0xFF3B82F6)
                                                    : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.add,
                                                  size: 14,
                                                  color: isInStock
                                                      ? Colors.white
                                                      : Colors.grey.shade500,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jami summa',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151)),
                      ),
                      Text(
                        NumberFormatter.formatDecimal(_totalAmount),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Faqat yopilmagan savdolar uchun to'lov tugmasi
                if (_sale?['status'] != 'Closed')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _cartItems.isEmpty ? null : _showPaymentDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cartItems.isEmpty
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('TO\'LOV QILISH',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3)),
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
      return _remainingAmount <= 0.01 ||
          (_remainingAmount > 0.01 && _totalPaid > 0);
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

// Price input dialog for editing item prices

// Return quantity dialog
