import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../screens/dashboard_screen.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/zakup_service.dart';
import '../bloc/zakup_bloc.dart';
import '../bloc/events/zakup_event.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import '../bloc/states/zakup_state.dart';

class ZakupScreen extends StatefulWidget {
  const ZakupScreen({super.key});

  @override
  State<ZakupScreen> createState() => _ZakupScreenState();
}

class _ZakupScreenState extends State<ZakupScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    // Load products (needed for dialog)
    _loadProducts();
    // Load zakups
    context.read<ZakupBloc>().add(const GetZakupsEvent());
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);
      final products = await productService.getAllProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      // Products loading failed - continue anyway
      setState(() {
        _products = [];
      });
    }
  }

  void _filterProducts() {
    setState(() {}); // Trigger rebuild for search filter
  }

  List<dynamic> _getFilteredProducts() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _products;
    } else {
      return _products.where((product) {
        final name = (product['name'] ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    }
  }

  void _showAddZakupDialog() async {
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

    final filteredProducts = _getFilteredProducts();
    if (filteredProducts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mahsulotlar yo\'q. Avval mahsulot qo\'shing'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final selectedProduct = await showDialog<dynamic>(
      context: context,
      builder: (context) => _AddZakupDialog(products: filteredProducts),
    );

    if (selectedProduct != null && mounted) {
      _showQuantityAndPriceDialog(selectedProduct);
    }
  }

  void _showQuantityAndPriceDialog(dynamic product) {
    final quantityController = TextEditingController();
    final costPriceController = TextEditingController();

    showDialog(
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
    ).then((confirmed) {
      if (confirmed == true) {
        _createZakup(
          product['id'],
          int.parse(quantityController.text),
          double.parse(costPriceController.text),
        );
      }
    });
  }

  void _createZakup(String productId, int quantity, double costPrice) {
    context.read<ZakupBloc>().add(CreateZakupEvent(
          productId: productId,
          quantity: quantity,
          costPrice: costPrice,
        ));
  }

  bool _isExporting = false;

  Future<void> _exportExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final zakupService = ZakupService(authProvider: authProvider);

      final bytes = await zakupService.downloadZakupsExcel();

      if (bytes != null && bytes.isNotEmpty) {
        final path = await core_file_helper.FileHelper.saveAndOpenExcel(
            bytes, 'Xaridlar.xlsx');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(path != null
                  ? 'Fayl saqlandi: $path'
                  : 'Faylni saqlashda xatolik yuz berdi'),
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
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'];
    final canAdd = userRole == 'Admin' || userRole == 'Owner';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<ZakupBloc, ZakupState>(
      listener: (context, state) {
        if (state is ZakupCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zakup muvaffaqiyatli qo\'shildi'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ZakupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.zakup,
          onRefresh: () =>
              context.read<ZakupBloc>().add(const GetZakupsEvent()),
          extraActions: [
            _isExporting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Excelga yuklash',
                    onPressed: _exportExcel,
                  ),
          ],
        ),
        body: Column(
          children: [
            BlocBuilder<ZakupBloc, ZakupState>(
              builder: (context, state) {
                if (state is ZakupLoading) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final zakups = state is ZakupLoaded
                    ? state.zakups.map((z) => z.toJson()).toList()
                    : [];

                if (state is ZakupError) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<ZakupBloc>()
                                .add(const GetZakupsEvent()),
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (zakups.isEmpty) {
                  return Expanded(
                    child: Center(
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
                    ),
                  );
                }

                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<ZakupBloc>().add(const GetZakupsEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: zakups.length,
                      itemBuilder: (context, index) {
                        final zakup = zakups[index];
                        return _buildZakupCard(zakup);
                      },
                    ),
                  ),
                );
              },
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
      ),
    );
  }

  Widget _buildZakupCard(Map<String, dynamic> zakup) {
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
            Text('Soni: ${(zakup['quantity'] as num?)?.toDouble() ?? 0.0}'),
            Text(
                'Olingan narxi: ${NumberFormatter.format(zakup['costPrice'] ?? 0)} so\'m'),
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
                            'Soni: ${(product['quantity'] as num?)?.toDouble() ?? 0.0} | Narxi: ${NumberFormatter.format(product['salePrice'] ?? 0)} so\'m',
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
