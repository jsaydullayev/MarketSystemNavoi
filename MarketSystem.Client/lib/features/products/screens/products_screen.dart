import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/product_service.dart';
import '../../../data/services/zakup_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/file_helper.dart' as core_file_helper;
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  final bool isReadOnly;

  const ProductsScreen({super.key, this.isReadOnly = false});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final products = await productService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(dynamic product) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final productService = ProductService(authProvider: authProvider);

        await productService.deleteProduct(product['id']);
        _loadProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deleteSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _quickZakup(dynamic product) async {
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

    final quantityController = TextEditingController();
    final costPriceController =
        TextEditingController(text: (product['costPrice'] ?? 0).toString());

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
      setState(() {
        _isLoading = true;
      });

      try {
        final zakupService = ZakupService(authProvider: authProvider);

        await zakupService.createZakup(
          productId: product['id'],
          quantity: int.parse(quantityController.text),
          costPrice: double.parse(costPriceController.text),
        );

        await _loadProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zakup muvaffaqiyatli qo\'shildi!'),
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
  }

  Future<void> _exportExcel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final bytes = await productService.downloadProductsExcel();
      
      if (bytes != null && bytes.isNotEmpty) {
        // Core dagi fayl yordamchisini chaqiramiz (import qilish shart emas, chunki tepadagi path orqali beramiz)
        final path = await core_file_helper.FileHelper.saveAndOpenExcel(bytes, 'Mahsulotlar.xlsx');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(path != null ? 'Fayl saqlandi: $path' : 'Faylni saqlashda xatolik yuz berdi'),
              backgroundColor: path != null ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
              content: Text('Ma\'lumotlarni yuklab olishda xatolik'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.products),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Excelga yuklash',
            onPressed: _exportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterProducts(),
              decoration: InputDecoration(
                hintText: l10n.search,
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
          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: Text(l10n.loading),
                            ),
                          ],
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No products found'
                                      : l10n.noData,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: !widget.isReadOnly
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductFormScreen(),
                  ),
                );
                if (result == true) {
                  _loadProducts();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProductCard(dynamic product) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final l10n = AppLocalizations.of(context)!;
    final canZakup = userRole == 'Admin' || userRole == 'Owner';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: Colors.orange,
          ),
        ),
        title: Text(
          product['name'] ?? 'Noma\'lum',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['categoryName'] != null) ...[
              Text(
                product['categoryName'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
                '${l10n.salePrice}: ${NumberFormatter.formatDecimal(product['salePrice'] ?? 0)}'),
            Text(
                '${l10n.costPrice}: ${NumberFormatter.formatDecimal(product['costPrice'] ?? 0)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.layers,
                  size: 16,
                  color: _getStockColor(product['quantity']?.toDouble()),
                ),
                const SizedBox(width: 4),
                Text(
                  'Soni: ${product['quantity']?.toString() ?? '0'} ${product['unitName'] ?? 'dona'}', // ✅ UNIT
                  style: TextStyle(
                    color: _getStockColor(product['quantity']?.toDouble()),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product['quantity'] <= product['minThreshold']) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.orange,
                  ),
                  Text(
                    ' Kam!',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (product['isTemporary'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: const Text(
                    'Vaqtinchalik',
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canZakup)
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.purple),
                tooltip: 'Zakup qo\'shish',
                onPressed: () => _quickZakup(product),
              ),
            if (!widget.isReadOnly) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
                    ),
                  );
                  if (result == true) {
                    _loadProducts();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteProduct(product),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStockColor(double? quantity) {
    if (quantity == null || quantity <= 0) return Colors.red;
    if (quantity <= 10) return Colors.orange;
    return Colors.green;
  }
}
