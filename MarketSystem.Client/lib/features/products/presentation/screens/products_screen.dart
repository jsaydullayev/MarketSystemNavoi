import 'package:flutter/material.dart';
import 'package:market_system_client/features/products/presentation/screens/product_form_screen.dart';
import 'package:market_system_client/features/products/presentation/widgets/product_body.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/zakup_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import 'package:market_system_client/core/extensions/app_extensions.dart';

extension Spacing on num {
  Widget get height => SizedBox(height: toDouble());
  Widget get width => SizedBox(width: toDouble());
}

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
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(dynamic product) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ProductService(authProvider: authProvider)
          .deleteProduct(product['id']);
      _loadProducts();
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  Future<void> _quickZakup(dynamic product) async {
    final l10n = AppLocalizations.of(context)!;
    final qtyController = TextEditingController();
    final costController =
        TextEditingController(text: (product['costPrice'] ?? 0).toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(product['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
                qtyController, l10n.quantity, Icons.add_shopping_cart, true),
            16.height,
            _buildDialogField(costController, l10n.costPrice,
                Icons.monetization_on_outlined, true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            child: Text(l10n.add),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await ZakupService(authProvider: authProvider).createZakup(
          productId: product['id'],
          quantity: int.parse(qtyController.text),
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

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(l10n, primaryColor, isDark),
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
    );
  }

  PreferredSizeWidget _buildAppBar(
      AppLocalizations l10n, Color primary, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Text(l10n.products,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold)),
      centerTitle: true,
      leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context)),
      actions: [
        IconButton(
            icon: Icon(Icons.file_download_outlined, color: primary),
            onPressed: _exportExcel),
        IconButton(
            icon: Icon(Icons.refresh_rounded, color: primary),
            onPressed: _loadProducts),
        8.width,
      ],
    );
  }
}
