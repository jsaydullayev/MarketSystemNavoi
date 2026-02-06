import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/sales_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/providers/auth_provider.dart';

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
    final existingIndex = _cartItems.indexWhere((item) => item['productId'] == product['id']);

    if (existingIndex != -1) {
      // Product exists - increase quantity
      setState(() {
        _cartItems[existingIndex]['quantity']++;
      });
    } else {
      // New product - add to cart
      setState(() {
        _cartItems.add({
          'productId': product['id'],
          'productName': product['name'],
          'salePrice': product['salePrice'],
          'costPrice': product['costPrice'],
          'quantity': 1,
          'comment': '',
        });
      });
    }
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
    } else {
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }
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

  void _showPaymentDialog(String saleId) {
    // Agar qarzga sotmoqchi bo'lsa, mijoz majburiy
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentDialog(
        saleId: saleId,
        totalAmount: _totalAmount,
        selectedCustomer: _selectedCustomer,
        onConfirm: (payments, useDebt) async {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            // Barcha to'lovlarni yuborish
            for (var payment in payments) {
              await salesService.addPayment(
                saleId: saleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
              );
            }

            if (mounted) {
              Navigator.pop(context); // Close dialog
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

    setState(() {
      _isCreating = true;
    });

    try {
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
          comment: item['comment'],
        );
      }

      setState(() {
        _isCreating = false;
      });

      // 3. Show payment dialog
      if (mounted) {
        _showPaymentDialog(sale['id']);
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
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
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi sotuv'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Customer selection & Cart summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      // Customer selection
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _showCustomerDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedCustomer != null
                                            ? '${_selectedCustomer!['fullName'] ?? 'Noma\'lum'} (${_selectedCustomer!['phone']})'
                                            : 'Mijozni tanlang (ixtiyoriy)',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jami summa:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_totalAmount.toStringAsFixed(0)} so\'m',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cart items
                if (_cartItems.isNotEmpty)
                  Container(
                    height: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['productName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['quantity']} x ${item['salePrice']} = ${(item['quantity'] * item['salePrice']).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _updateQuantity(index, item['quantity'] - 1),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.remove, size: 16),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('${item['quantity']}'),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => _updateQuantity(index, item['quantity'] + 1),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.add, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () => _removeFromCart(index),
                                        child: const Icon(Icons.delete, color: Colors.red, size: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Products list
                Expanded(
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Mahsulot qidirish...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterProducts();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),

                      // Products grid
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? const Center(child: Text('Mahsulotlar topilmadi'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final quantity = product['quantity'] ?? 0;
                                  final isInStock = quantity > 0;

                                  return Card(
                                    elevation: 2,
                                    color: isInStock ? null : Colors.grey.shade300,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'Noma\'lum',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Narxi: ${product['salePrice']} so\'m',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Soni: $quantity',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: quantity > 5 ? Colors.black : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Chip(
                                                label: Text(
                                                  isInStock ? 'Sotuvda' : 'Tugadi',
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                                backgroundColor: isInStock
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                padding: EdgeInsets.zero,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_shopping_cart),
                                                onPressed: isInStock
                                                    ? () => _addToCart(product)
                                                    : null,
                                                color: isInStock ? Colors.blue : Colors.grey,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _completeSale,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isCreating ? 'Sotilmoqda...' : 'SOTISH (${_cartItems.length} mahsulot)',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cartItems.isEmpty ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Payment Dialog Widget
class _PaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;

  const _PaymentDialog({
    super.key,
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useDebt = false;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _transferController = TextEditingController();

  bool _isProcessing = false;

  double get _totalPaid {
    double total = 0;
    if (_useCash) total += double.tryParse(_cashController.text) ?? 0;
    if (_useTerminal) total += double.tryParse(_terminalController.text) ?? 0;
    if (_useTransfer) total += double.tryParse(_transferController.text) ?? 0;
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _totalPaid;

  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  bool _canConfirm() {
    if (_hasDebt) {
      // Qarzga sotish - mijoz bo'lishi shart
      return widget.selectedCustomer != null && _totalPaid >= 0;
    } else {
      // To'liq to'lash
      return _remainingAmount <= 0.01;
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _terminalController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerDebt = widget.selectedCustomer?['totalDebt'] ?? 0;

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
              subtitle: const Text('Cash', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              subtitle: const Text('Terminal', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              subtitle: const Text('Transfer', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

            // Qarzga (Debt)
            CheckboxListTile(
              title: const Text('Qarzga olish'),
              subtitle: widget.selectedCustomer != null
                  ? Text('${widget.selectedCustomer!['fullName'] ?? 'Mijoz'} - Hozirgi qarz: $customerDebt so\'m',
                      style: const TextStyle(fontSize: 12, color: Colors.blue))
                  : const Text('Mijoz tanlang', style: TextStyle(fontSize: 12, color: Colors.red)),
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
                      const Text('Jami summa:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.totalAmount.toStringAsFixed(0)} so\'m'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To\'langan:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_totalPaid.toStringAsFixed(0)} so\'m', style: const TextStyle(color: Colors.green)),
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
                        '${_remainingAmount.toStringAsFixed(0)} so\'m',
                        style: TextStyle(
                          color: _hasDebt ? Colors.orange : (_remainingAmount > 0.01 ? Colors.red : Colors.green),
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
                          const Text('Yangi qarz:', style: TextStyle(fontSize: 11, color: Colors.orange)),
                          Text(
                            '+${_remainingAmount.toStringAsFixed(0)} so\'m',
                            style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
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
