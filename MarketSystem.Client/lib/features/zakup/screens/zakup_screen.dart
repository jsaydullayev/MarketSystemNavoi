import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/zakup_service.dart';
import '../../../data/services/product_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../screens/dashboard_screen.dart';

class ZakupScreen extends StatefulWidget {
  const ZakupScreen({super.key});

  @override
  State<ZakupScreen> createState() => _ZakupScreenState();
}

class _ZakupScreenState extends State<ZakupScreen> {
  List<dynamic> _zakups = [];
  List<dynamic> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final zakupService = ZakupService(authProvider: authProvider);
      final productService = ProductService(authProvider: authProvider);

      final zakups = await zakupService.getAllZakups();
      final products = await productService.getAllProducts();

      setState(() {
        _zakups = zakups;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddZakupDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];

    if (userRole != 'Admin' && userRole != 'Owner') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faqat Admin va Owner zakup qo\'sha oladi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final selectedProduct = await showDialog<dynamic>(
      context: context,
      builder: (context) => _AddZakupDialog(products: _products),
    );

    if (selectedProduct != null && mounted) {
      _showQuantityAndPriceDialog(selectedProduct);
    }
  }

  Future<void> _showQuantityAndPriceDialog(dynamic product) async {
    final quantityController = TextEditingController();
    final costPriceController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product['name']} - Zakup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Soni',
                prefixIcon: Icon(Icons.layers),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costPriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Olingan narxi (so\'m)',
                prefixIcon: Icon(Icons.money_off),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              if (quantityController.text.isNotEmpty &&
                  costPriceController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _createZakup(
        product['id'],
        int.parse(quantityController.text),
        double.parse(costPriceController.text),
      );
    }
  }

  Future<void> _createZakup(String productId, int quantity, double costPrice) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final zakupService = ZakupService(authProvider: authProvider);

      await zakupService.createZakup(
        productId: productId,
        quantity: quantity,
        costPrice: costPrice,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zakup muvaffaqiyatli qo\'shildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'];
    final canAdd = userRole == 'Admin' || userRole == 'Owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xaridlar (Zakup)'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _zakups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Xaridlar yo\'q',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _zakups.length,
                          itemBuilder: (context, index) {
                            final zakup = _zakups[index];
                            return _buildZakupCard(zakup);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _showAddZakupDialog,
              icon: const Icon(Icons.add),
              label: const Text('Zakup qo\'shish'),
            )
          : null,
    );
  }

  Widget _buildZakupCard(dynamic zakup) {
    final createdAt = DateTime.tryParse(zakup['createdAt'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.shopping_bag,
            color: Colors.purple,
          ),
        ),
        title: Text(
          zakup['productName'] ?? 'Noma\'lum',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soni: ${zakup['quantity'] ?? 0}'),
            Text('Olingan narxi: ${zakup['costPrice'] ?? 0} so\'m'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Qo\'shdi: ${zakup['createdBy'] ?? 'Noma\'lum'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (createdAt != null)
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AddZakupDialog extends StatefulWidget {
  final List<dynamic> products;

  const _AddZakupDialog({required this.products});

  @override
  State<_AddZakupDialog> createState() => _AddZakupDialogState();
}

class _AddZakupDialogState extends State<_AddZakupDialog> {
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
                        return ListTile(
                          title: Text(product['name'] ?? 'Noma\'lum'),
                          subtitle: Text(
                            'Soni: ${product['quantity'] ?? 0} | Narxi: ${product['salePrice'] ?? 0} so\'m',
                          ),
                          onTap: () => Navigator.pop(context, product),
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
          child: const Text('Bekor qilish'),
        ),
      ],
    );
  }
}
