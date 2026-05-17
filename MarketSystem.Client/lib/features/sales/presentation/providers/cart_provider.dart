import 'package:flutter/material.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/customer_service.dart';
import '../../../../data/services/sales_service.dart';

class CartProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  CartProvider(this._authProvider);

  List<dynamic> _products = [];
  List<dynamic> _customers = [];
  final List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _selectedCustomer;
  String? _selectedCategoryName;
  String _searchQuery = '';

  bool isLoading = false;
  bool isCreating = false;
  String? errorMessage;

  List<dynamic> get products => _products;
  List<dynamic> get customers => _customers;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  Map<String, dynamic>? get selectedCustomer => _selectedCustomer;
  String? get selectedCategoryName => _selectedCategoryName;
  bool get isEmpty => _cartItems.isEmpty;
  int get itemCount => _cartItems.length;

  List<dynamic> get filteredProducts => _products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final matchesSearch =
            _searchQuery.isEmpty || name.contains(_searchQuery);
        final matchesCategory = _selectedCategoryName == null ||
            p['categoryName'] == _selectedCategoryName;
        return matchesSearch && matchesCategory;
      }).toList();

  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      final cat = p['categoryName'];
      if (cat is String && cat.trim().isNotEmpty) set.add(cat.trim());
    }
    return set.toList()..sort();
  }

  double get totalAmount => _cartItems.fold(0.0, (sum, item) {
        final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
        return sum + price * qty;
      });

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void selectCategory(String? category) {
    _selectedCategoryName = category;
    notifyListeners();
  }

  void selectCustomer(Map<String, dynamic>? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addToCart(Map<String, dynamic> item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, double qty) {
    if (qty <= 0) {
      removeFromCart(index);
    } else {
      _cartItems[index]['quantity'] = qty;
      notifyListeners();
    }
  }

  void updateItemPrice(int index, double price, double qty, String? comment) {
    _cartItems[index]['salePrice'] = price;
    _cartItems[index]['quantity'] = qty;
    if (comment != null && comment.isNotEmpty) {
      _cartItems[index]['comment'] = comment;
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final productService = ProductService(authProvider: _authProvider);
      final customerService = CustomerService(authProvider: _authProvider);

      // Parallel loading
      final results = await Future.wait([
        productService.getAllProducts(),
        customerService.getAllCustomers(),
      ]);

      _products = results[0];
      _customers = results[1];
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveAsDraft() async {
    if (_cartItems.isEmpty) return false;
    isCreating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final salesService = SalesService(authProvider: _authProvider);
      final sale = await salesService.createSale(
        customerId: _selectedCustomer?['id'],
      );

      for (final item in _cartItems) {
        if (item['isExternal'] == true) {
          await salesService.addSaleItem(
            saleId: sale['id'],
            isExternal: true,
            externalProductName: item['productName'] as String?,
            externalCostPrice:
                (item['externalCostPrice'] as num?)?.toDouble() ?? 0.0,
            quantity: (item['quantity'] as num).toDouble(),
            salePrice: (item['salePrice'] as num).toDouble(),
            minSalePrice: 0.0,
            comment: item['comment'] as String?,
          );
        } else {
          await salesService.addSaleItem(
            saleId: sale['id'],
            productId: item['productId'] as String?,
            quantity: (item['quantity'] as num).toDouble(),
            salePrice: (item['salePrice'] as num).toDouble(),
            minSalePrice:
                (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
            comment: item['comment'] as String?,
          );
        }
      }

      isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      isCreating = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
