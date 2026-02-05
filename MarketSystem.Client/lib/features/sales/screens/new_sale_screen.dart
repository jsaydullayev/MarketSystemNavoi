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
  dynamic _currentSale;

  bool _isLoading = false;
  bool _isCreating = false;
  double _totalAmount = 0;
  double _paidAmount = 0;
  double _remainingAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _createSale() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      // Create sale
      final sale = await salesService.createSale(
        customerId: _selectedCustomer?['id'],
      );

      setState(() {
        _currentSale = sale;
      });

      // Add items to sale
      for (var item in _cartItems) {
        await salesService.addSaleItem(
          saleId: sale['id'],
          productId: item['productId'],
          quantity: item['quantity'],
          salePrice: item['salePrice'],
          comment: item['comment'],
        );
      }

      // Add payment
      if (_paidAmount > 0) {
        await salesService.addPayment(
          saleId: sale['id'],
          paymentType: 'Naqd', // Default to cash
          amount: _paidAmount,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sotuv muvaffaqiyatli yaratildi!'),
            backgroundColor: Colors.green,
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
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addToCart(dynamic product) {
    final existingItem = _cartItems.firstWhere(
      (item) => item['productId'] == product['id'],
      orElse: () => {},
    );

    if (existingItem.isNotEmpty) {
      setState(() {
        existingItem['quantity'] += 1;
        existingItem['totalPrice'] =
            existingItem['quantity'] * existingItem['salePrice'];
      });
    } else {
      setState(() {
        _cartItems.add({
          'productId': product['id'],
          'productName': product['name'],
          'salePrice': (product['salePrice'] ?? 0).toDouble(),
          'quantity': 1,
          'totalPrice': (product['salePrice'] ?? 0).toDouble(),
          'comment': null,
        });
      });
    }

    _calculateTotals();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() {
        _cartItems.removeAt(index);
      });
    } else {
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
        _cartItems[index]['totalPrice'] =
            newQuantity * _cartItems[index]['salePrice'];
      });
    }

    _calculateTotals();
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    _calculateTotals();
  }

  void _calculateTotals() {
    setState(() {
      _totalAmount = _cartItems.fold(
          0, (sum, item) => sum + (item['totalPrice'] as double));
      _remainingAmount = _totalAmount - _paidAmount;
    });
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        products: _products,
        onAdd: (product) {
          _addToCart(product);
        },
      ),
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomerDialog(
        customers: _customers,
        selectedCustomer: _selectedCustomer,
        onSelect: (customer) {
          setState(() {
            _selectedCustomer = customer;
          });
        },
      ),
    );
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
                // Customer selection
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(_selectedCustomer == null
                        ? 'Mijoz tanlang'
                        : '${_selectedCustomer!['fullName'] ?? 'Noma\'lum'} (${_selectedCustomer!['phone']})'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showCustomerDialog,
                  ),
                ),

                // Cart items
                Expanded(
                  child: _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Savatcha bo\'sh',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return _buildCartItem(item, index);
                          },
                        ),
                ),

                // Totals and checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jami:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '${_totalAmount.toStringAsFixed(0)} so\'m',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('To\'langan:'),
                          Text('${_paidAmount.toStringAsFixed(0)} so\'m'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Qarzdorlik:'),
                          Text(
                            '${_remainingAmount.toStringAsFixed(0)} so\'m',
                            style: TextStyle(
                              color: _remainingAmount > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showAddProductDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Mahsulot'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _cartItems.isEmpty || _isCreating
                                  ? null
                                  : _createSale,
                              icon: _isCreating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(_isCreating ? 'Saqlash...' : 'Tugatish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item['productName']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Narxi: ${item['salePrice'].toStringAsFixed(0)} so\'m'),
            Text('Jami: ${item['totalPrice'].toStringAsFixed(0)} so\'m',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () => _updateQuantity(index, item['quantity'] - 1),
            ),
            Text(
              '${item['quantity']}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _updateQuantity(index, item['quantity'] + 1),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFromCart(index),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  final List<dynamic> products;
  final Function(dynamic) onAdd;

  const _AddProductDialog({
    required this.products,
    required this.onAdd,
  });

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
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
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products.where((product) {
          final name = (product['name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mahsulot tanlang'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Mahsulot qidirish...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? const Center(child: Text('Mahsulot topilmadi'))
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final quantity = product['quantity'] ?? 0;
                        final isOutOfStock = quantity <= 0;

                        return ListTile(
                          title: Text(product['name'] ?? 'Noma\'lum'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Narxi: ${product['salePrice'] ?? 0} so\'m'),
                              Text(
                                'Soni: $quantity',
                                style: TextStyle(
                                  color: isOutOfStock ? Colors.red : Colors.grey,
                                  fontWeight: isOutOfStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          onTap: isOutOfStock
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  widget.onAdd(product);
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Yopish'),
        ),
      ],
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  final List<dynamic> customers;
  final Map<String, dynamic>? selectedCustomer;
  final Function(Map<String, dynamic>) onSelect;

  const _CustomerDialog({
    required this.customers,
    required this.selectedCustomer,
    required this.onSelect,
  });

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mijoz tanlang'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: widget.customers.isEmpty
                  ? const Center(child: Text('Mijozlar yo\'q'))
                  : ListView.builder(
                      itemCount: widget.customers.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "Mijoz tanlanmagan" option
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Mijoz tanlanmagan'),
                            selected: widget.selectedCustomer == null,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSelect({});
                            },
                          );
                        }

                        final customer = widget.customers[index - 1];
                        final isSelected =
                            widget.selectedCustomer?['id'] == customer['id'];

                        return ListTile(
                          leading: Icon(
                            Icons.person,
                            color: isSelected ? Colors.green : null,
                          ),
                          title: Text(
                              customer['fullName'] ?? 'Noma\'lum mijoz'),
                          subtitle: Text(customer['phone'] ?? ''),
                          selected: isSelected,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelect(customer);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Yopish'),
        ),
      ],
    );
  }
}
