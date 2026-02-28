import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/category_service.dart';
import '../../../../data/models/product_category_model.dart';
import '../../../../core/providers/auth_provider.dart';

extension Spacing on num {
  Widget get height => SizedBox(height: toDouble());
  Widget get width => SizedBox(width: toDouble());
}

class ProductBottomSheet extends StatefulWidget {
  final dynamic product;

  const ProductBottomSheet({super.key, this.product});

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minSalePriceController = TextEditingController();
  final _minThresholdController = TextEditingController();

  bool _isTemporary = false;
  bool _isLoading = false;
  List<ProductCategoryModel> _categories = [];
  int? _selectedCategory;

  int _selectedUnit = 1;
  final List<Map<String, dynamic>> _units = [
    {'value': 1, 'name': 'dona', 'icon': Icons.inventory_2_outlined},
    {'value': 2, 'name': 'kg', 'icon': Icons.scale_outlined},
    {'value': 3, 'name': 'm', 'icon': Icons.straighten_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _minSalePriceController.text =
          (widget.product['minSalePrice'] ?? 0).toString();
      _minThresholdController.text =
          (widget.product['minThreshold'] ?? 0).toString();
      _isTemporary = widget.product['isTemporary'] ?? false;
      _selectedCategory = widget.product['categoryId'];
      _selectedUnit = widget.product['unit'] ?? 1;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final categoryService = CategoryService(authProvider: authProvider);
      final categories = await categoryService.getAllCategories();
      setState(() {
        final seen = <int>{};
        _categories = categories.where((c) => seen.add(c.id)).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _minSalePriceController.dispose();
    _minThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final data = {
        'name': _nameController.text.trim(),
        'salePrice': double.parse(_salePriceController.text),
        'minSalePrice': double.parse(_minSalePriceController.text),
        'minThreshold': int.parse(_minThresholdController.text),
        'categoryId': _selectedCategory,
        'unit': _selectedUnit,
        'isTemporary': _isTemporary,
      };

      if (widget.product == null) {
        await productService.createProduct(
          name: data['name'] as String,
          isTemporary: data['isTemporary'] as bool,
          salePrice: data['salePrice'] as double,
          minSalePrice: data['minSalePrice'] as double,
          minThreshold: data['minThreshold'] as int,
          categoryId: data['categoryId'] as int?,
          unit: data['unit'] as int,
        );
      } else {
        await productService.updateProduct(
          id: widget.product['id'],
          name: data['name'] as String,
          salePrice: data['salePrice'] as double,
          minSalePrice: data['minSalePrice'] as double,
          minThreshold: data['minThreshold'] as int,
          categoryId: data['categoryId'] as int?,
          unit: data['unit'] as int,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Xatolik: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 500 : double.infinity,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10))),
                  20.height,
                  Text(
                      widget.product != null
                          ? l10n.editProduct
                          : l10n.addProduct,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  25.height,
                  _buildField(
                      controller: _nameController,
                      label: l10n.productName,
                      icon: Icons.inventory_2_rounded),
                  16.height,
                  Row(
                    children: [
                      Expanded(child: _buildCategoryDropdown(isDark, l10n)),
                      12.width,
                      Expanded(child: _buildUnitDropdown(isDark, l10n)),
                    ],
                  ),
                  16.height,
                  Row(
                    children: [
                      Expanded(
                          child: _buildField(
                              controller: _salePriceController,
                              label: l10n.salePrice,
                              icon: Icons.payments_outlined,
                              isNumber: true)),
                      12.width,
                      Expanded(
                          child: _buildField(
                              controller: _minSalePriceController,
                              label: l10n.minPrice,
                              icon: Icons.trending_down,
                              isNumber: true)),
                    ],
                  ),
                  16.height,
                  Row(
                    children: [
                      Expanded(
                          child: _buildField(
                              controller: _minThresholdController,
                              label: l10n.minThreshold,
                              icon: Icons.warning_amber,
                              isNumber: true)),
                      12.width,
                      _buildTempSwitch(isDark, l10n),
                    ],
                  ),
                  24.height,
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.product != null ? l10n.save : l10n.add),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (v) => (v == null || v.isEmpty) ? 'To\'ldiring' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.08),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark, AppLocalizations l10n) {
    final uniqueCategories = _categories
        .fold<Map<int, ProductCategoryModel>>(
          {},
          (map, c) => map..[c.id] = c,
        )
        .values
        .toList();

    final validIds = uniqueCategories.map((c) => c.id).toSet();
    final safeCategory =
        (_selectedCategory != null && validIds.contains(_selectedCategory))
            ? _selectedCategory
            : null;

    return DropdownButtonFormField<int?>(
      value: safeCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.categories,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.08),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
      items: [
        DropdownMenuItem(
            value: null, child: Text(l10n.no, style: TextStyle(fontSize: 14))),
        ...uniqueCategories.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)))),
      ],
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _buildUnitDropdown(bool isDark, AppLocalizations l10n) {
    final validValues = _units.map((u) => u['value'] as int).toSet();
    final safeValue = validValues.contains(_selectedUnit) ? _selectedUnit : 1;

    return DropdownButtonFormField<int>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: l10n.unit,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.08),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
      items: _units
          .map((u) => DropdownMenuItem(
              value: u['value'] as int,
              child: Text(u['name'] as String,
                  style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() => _selectedUnit = v!),
    );
  }

  Widget _buildTempSwitch(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: Colors.purple),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _isTemporary,
              activeColor: Colors.purple,
              onChanged: (v) => setState(() => _isTemporary = v),
            ),
          ),
        ],
      ),
    );
  }
}
