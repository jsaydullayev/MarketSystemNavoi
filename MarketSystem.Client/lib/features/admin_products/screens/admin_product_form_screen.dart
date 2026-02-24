import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/product_service.dart';
import '../../../data/services/category_service.dart';
import '../../../core/providers/auth_provider.dart';

class AdminProductFormScreen extends StatefulWidget {
  final dynamic product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minSalePriceController = TextEditingController();
  final _minThresholdController = TextEditingController();

  bool _isTemporary = false;
  bool _isLoading = false;
  List<dynamic> _categories = [];
  dynamic _selectedCategory;
  bool _isLoadingCategories = true;

  // ✅ UNIT DROPDOWN
  int _selectedUnit = 1; // Default: dona (Piece)
  final List<Map<String, dynamic>> _units = [
    {'value': 1, 'name': 'dona', 'icon': Icons.inventory_2_outlined},
    {'value': 2, 'name': 'kg', 'icon': Icons.scale},
    {'value': 3, 'name': 'm', 'icon': Icons.straighten},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _minSalePriceController.text = (widget.product['minSalePrice'] ?? 0).toString();
      _minThresholdController.text = (widget.product['minThreshold'] ?? 0).toString();
      _isTemporary = widget.product['isTemporary'] ?? false;
      _selectedCategory = widget.product['categoryId'];
      _selectedUnit = widget.product['unit'] ?? 1; // ✅ LOAD UNIT
    }
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final categoryService = CategoryService(authProvider: authProvider);
      final categories = await categoryService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final salePrice = double.parse(_salePriceController.text);
      final minSalePrice = double.parse(_minSalePriceController.text);
      final minThreshold = int.parse(_minThresholdController.text);

      if (widget.product == null) {
        // Create new product (Admin cannot set costPrice or quantity)
        final name = _nameController.text.trim();
        await productService.createProduct(
          name: name,
          isTemporary: _isTemporary,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,  // ✅ NEW: UNIT
        );
      } else {
        // Update existing product - Admin can only update prices and minThreshold
        // Cannot update name, costPrice, or quantity
        await productService.updateProduct(
          id: widget.product['id'],
          name: widget.product['name'], // Keep original name
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: widget.product['unit'] ?? _selectedUnit,  // ✅ NEW: Keep original unit
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
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
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Admin: Mahsulotni tahrirlash' : 'Admin: Yangi mahsulot'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin faqat narxlarni va sozlamalarni o\'zgartira oladi',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name field (read-only when editing)
            if (!isEditing)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Mahsulot nomi',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mahsulot nomini kiriting';
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: _nameController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Mahsulot nomi',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Category dropdown
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<dynamic>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategoriya',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'Kategoriyani tanlang',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Kategoriya tanlanmagan'),
                      ),
                      ..._categories.map<DropdownMenuItem<dynamic>>((category) {
                        return DropdownMenuItem<dynamic>(
                          value: category['id'],
                          child: Text(category['name'] ?? ''),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
            const SizedBox(height: 16),

            // ✅ UNIT DROPDOWN - NEW
            DropdownButtonFormField<int>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'O\'lchov birligi',
                prefixIcon: Icon(Icons.straighten),
                border: OutlineInputBorder(),
                hintText: 'Birligni tanlang',
              ),
              items: _units.map<DropdownMenuItem<int>>((unit) {
                return DropdownMenuItem<int>(
                  value: unit['value'] as int,
                  child: Row(
                    children: [
                      Icon(unit['icon'] as IconData),
                      const SizedBox(width: 12),
                      Text(unit['name'] as String),
                      const SizedBox(width: 8),
                      Text(
                        unit['value'] == 1 ? '(dona)' :
                        unit['value'] == 2 ? '(kilogram)' :
                        '(metr)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedUnit = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // IsTemporary checkbox
            CheckboxListTile(
              title: const Text('Vaqtinchalik mahsulot'),
              subtitle: const Text('Omborda vaqtincha saqlanadigan mahsulot'),
              value: _isTemporary,
              onChanged: (value) {
                setState(() {
                  _isTemporary = value ?? false;
                });
              },
            ),
            const SizedBox(height: 16),

            // Sale Price field
            TextFormField(
              controller: _salePriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Sotish narxi (so\'m)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Sotish narxini kiriting';
                }
                if (double.tryParse(value) == null) {
                  return 'To\'g\'ri narx kiriting';
                }
                if (double.parse(value) <= 0) {
                  return 'Narx musbat bo\'lishi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Min Sale Price field
            TextFormField(
              controller: _minSalePriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Minimum sotish narxi (so\'m)',
                prefixIcon: Icon(Icons.trending_down),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Minimum sotish narxini kiriting';
                }
                if (double.tryParse(value) == null) {
                  return 'To\'g\'ri narx kiriting';
                }
                if (double.parse(value) < 0) {
                  return 'Narx manfiy bo\'lmasligi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Min Threshold field
            TextFormField(
              controller: _minThresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum chegara (ogohlantirish uchun)',
                prefixIcon: Icon(Icons.warning),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Minimum chegara kiriting';
                }
                if (int.tryParse(value) == null) {
                  return 'To\'g\'ri son kiriting';
                }
                if (int.parse(value) < 0) {
                  return 'Son manfiy bo\'lmasligi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Info about quantity
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Mahsulot soni: ${(widget.product['quantity'] as num?)?.toDouble() ?? 0.0} (o\'zgarmas)'
                          : 'Mahsulot soni 0 bilan yaratiladi, keyin Zakup orqali oshiriladi',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Saqlash' : 'Qo\'shish',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
