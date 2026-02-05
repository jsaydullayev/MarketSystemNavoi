import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/product_service.dart';
import '../../../core/providers/auth_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final dynamic product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minSalePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minThresholdController = TextEditingController();

  bool _isTemporary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _costPriceController.text = (widget.product['costPrice'] ?? 0).toString();
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _minSalePriceController.text = (widget.product['minSalePrice'] ?? 0).toString();
      _quantityController.text = (widget.product['quantity'] ?? 0).toString();
      _minThresholdController.text = (widget.product['minThreshold'] ?? 0).toString();
      _isTemporary = widget.product['isTemporary'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _minSalePriceController.dispose();
    _quantityController.dispose();
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

      final name = _nameController.text.trim();
      final costPrice = double.parse(_costPriceController.text);
      final salePrice = double.parse(_salePriceController.text);
      final minSalePrice = double.parse(_minSalePriceController.text);
      final quantity = int.parse(_quantityController.text);
      final minThreshold = int.parse(_minThresholdController.text);

      if (widget.product == null) {
        // Create new product
        await productService.createProduct(
          name: name,
          isTemporary: _isTemporary,
          costPrice: costPrice,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          quantity: quantity,
          minThreshold: minThreshold,
        );
      } else {
        // Update existing product
        await productService.updateProduct(
          id: widget.product['id'],
          name: name,
          costPrice: costPrice,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          quantity: quantity,
          minThreshold: minThreshold,
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
        title: Text(isEditing ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
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

            // Cost Price field
            TextFormField(
              controller: _costPriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Olingan narxi (so\'m)',
                prefixIcon: Icon(Icons.money_off),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Olingan narxni kiriting';
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

            // Quantity field
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Soni',
                prefixIcon: Icon(Icons.layers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Soni kiriting';
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
