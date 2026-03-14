import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/features/products/presentation/screens/product_form_screen.dart';
import 'package:market_system_client/features/products/presentation/widgets/product_body.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/zakup_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;

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
      _filteredProducts = query.isEmpty
          ? _products
          : _products
              .where((p) => (p['name'] ?? '').toLowerCase().contains(query))
              .toList();
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
      final errorMsg = e.toString();
      setState(() {
        // ✅ Tuzatilgan: Aniqroq xato xabari
        if (errorMsg.contains('SocketException') ||
            errorMsg.contains('Connection refused')) {
          _errorMessage =
              'Server bilan aloqa yo\'q. Backend server ishlayaptimi? (103.125.217.28:8080)';
        } else if (errorMsg.contains('401') ||
            errorMsg.contains('Unauthorized')) {
          _errorMessage = 'Login amali eskirgan. Iltimos, qayta login qiling.';
        } else if (errorMsg.contains('403') || errorMsg.contains('Forbidden')) {
          _errorMessage =
              'Ruxsat yo\'q. Siz bu amalni bajarish huquqiga ega emassiz.';
        } else {
          _errorMessage = 'Mahsulotlarni yuklashda xato: $errorMsg';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(
    dynamic product,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _products.removeWhere((p) => p['id'] == product['id']);
      _filteredProducts.removeWhere((p) => p['id'] == product['id']);
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ProductService(authProvider: authProvider)
          .deleteProduct(product['id']);
    } catch (e) {
      setState(() {
        _products.add(product);
        _filteredProducts.add(product);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.productUsedInSales),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _quickZakup(dynamic product) async {
    final l10n = AppLocalizations.of(context)!;
    final qtyController = TextEditingController();
    final costController =
        TextEditingController(text: (product['costPrice'] ?? 0).toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_rounded,
                          color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.zakup,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white38 : Colors.grey)),
                          Text(product['name'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDialogField(qtyController, l10n.quantity,
                    Icons.add_shopping_cart, true),
                const SizedBox(height: 12),
                _buildDialogField(costController, l10n.costPrice,
                    Icons.monetization_on_outlined, true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(l10n.cancel,
                            style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(l10n.add,
                            style: TextStyle(
                                color: isDark ? primary : Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await ZakupService(authProvider: authProvider).createZakup(
          productId: product['id'],
          quantity: double.parse(qtyController.text),
          costPrice: double.parse(costController.text),
        );
        _loadProducts();
        _showSnackBar(l10n.zakupSuccess, Colors.green);
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), Colors.red);
      }
    }
  }

  Widget _buildDialogField(TextEditingController controller, String label,
      IconData icon, bool isNum) {
    return TextField(
      controller: controller,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Future<void> _exportExcel() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bytes = await ProductService(authProvider: authProvider)
          .downloadProductsExcel();
      if (bytes != null && bytes.isNotEmpty) {
        await core_file_helper.FileHelper.saveAndOpenExcel(
            bytes, 'Mahsulotlar.xlsx');
      }
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  void _openProductForm({dynamic product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductBottomSheet(product: product),
    ).then((value) {
      if (value == true) _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return NetworkWrapper(
      onRetry: _loadProducts,
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.products,
          onRefresh: _loadProducts,
          extraActions: [
            IconButton(
              icon: Icon(Icons.file_download_outlined, color: primaryColor),
              onPressed: _exportExcel,
            ),
          ],
        ),
        body: ProductsBody(
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          products: _filteredProducts,
          searchController: _searchController,
          onRefresh: _loadProducts,
          onDelete: _deleteProduct,
          onEdit: (p) => _openProductForm(product: p),
          onZakup: _quickZakup,
          isReadOnly: widget.isReadOnly,
        ),
        floatingActionButton: !widget.isReadOnly
            ? FloatingActionButton(
                onPressed: () => _openProductForm(),
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              )
            : null,
      ),
    );
  }
}
