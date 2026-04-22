import 'package:flutter/material.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ProductsBody extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> products;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final Function(dynamic) onDelete;
  final Function(dynamic) onEdit;
  final Function(dynamic) onZakup;
  final bool isReadOnly;
  final bool canViewCostPrice;

  const ProductsBody({
    required this.isLoading,
    this.errorMessage,
    required this.products,
    required this.searchController,
    required this.onRefresh,
    required this.onDelete,
    required this.onEdit,
    required this.onZakup,
    required this.isReadOnly,
    required this.canViewCostPrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800), // Web uchun cheklov
        child: Column(
          children: [
            _SearchBar(
                controller: searchController,
                l10n: l10n,
                primaryColor: primaryColor,
                isDark: isDark),
            Expanded(
              child: isLoading && products.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : errorMessage != null
                      ? _ErrorView(
                          message: errorMessage!,
                          onRetry: onRefresh,
                          l10n: l10n)
                      : products.isEmpty
                          ? _EmptyView(l10n: l10n, primaryColor: primaryColor)
                          : RefreshIndicator(
                              onRefresh: onRefresh,
                              color: primaryColor,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: products.length,
                                itemBuilder: (context, index) => _ProductCard(
                                  product: products[index],
                                  l10n: l10n,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  onDelete: onDelete,
                                  onEdit: onEdit,
                                  onZakup: onZakup,
                                  isReadOnly: isReadOnly,
                                  canViewCostPrice: canViewCostPrice,
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;
  final Color primaryColor;
  final bool isDark;

  const _SearchBar(
      {required this.controller,
      required this.l10n,
      required this.primaryColor,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration:
          BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.search,
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
          filled: true,
          fillColor: isDark ? Colors.black26 : Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final AppLocalizations l10n;
  final bool isDark;
  final Color primaryColor;
  final Function(dynamic) onDelete;
  final Function(dynamic) onEdit;
  final Function(dynamic) onZakup;
  final bool isReadOnly;
  final bool canViewCostPrice;

  const _ProductCard({
    required this.product,
    required this.l10n,
    required this.isDark,
    required this.primaryColor,
    required this.onDelete,
    required this.onEdit,
    required this.onZakup,
    required this.isReadOnly,
    required this.canViewCostPrice,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canZakup = authProvider.user?['role'] == 'Admin' ||
        authProvider.user?['role'] == 'Owner';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('product_${product['id']}'),
        background: _buildSwipeBg(
            color: Colors.blue,
            icon: Icons.edit_rounded,
            label: 'Edit',
            align: Alignment.centerLeft),
        secondaryBackground: _buildSwipeBg(
            color: Colors.redAccent,
            icon: Icons.delete_forever_rounded,
            label: l10n.delete,
            align: Alignment.centerRight),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit(product);
            return false;
          } else {
            final confirmed = await _confirmDelete(context);
            return confirmed;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onDelete(product);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              _Avatar(primaryColor: primaryColor),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? 'N/A',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87)),
                    if (product['categoryName'] != null)
                      Text(product['categoryName'],
                          style: TextStyle(
                              color: primaryColor.withOpacity(0.8),
                              fontSize: 12)),
                    8.height,
                    _PriceRow(
                        product: product,
                        l10n: l10n,
                        isDark: isDark,
                        canViewCostPrice: canViewCostPrice),
                    8.height,
                    _StockBadge(
                      product: product,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              if (canZakup)
                IconButton(
                    icon: const Icon(Icons.add_shopping_cart_rounded,
                        color: Colors.purple, size: 22),
                    onPressed: () => onZakup(product)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBg(
      {required Color color,
      required IconData icon,
      required String label,
      required Alignment align}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      alignment: align,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.confirmDelete),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.no)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.yes,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;
  }
}

class _Avatar extends StatelessWidget {
  final Color primaryColor;
  const _Avatar({required this.primaryColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.inventory_2_rounded, color: primaryColor, size: 28),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final dynamic product;
  final AppLocalizations l10n;
  final bool isDark;
  final bool canViewCostPrice;
  const _PriceRow(
      {required this.product,
      required this.l10n,
      required this.isDark,
      required this.canViewCostPrice});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Badge(
            label: l10n.salePrice,
            price: product['salePrice'],
            color: Colors.green,
            isDark: isDark),
        if (canViewCostPrice) ...[
          12.width,
          _Badge(
              label: l10n.costPrice,
              price: product['costPrice'],
              color: Colors.blueGrey,
              isDark: isDark),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final dynamic price;
  final Color color;
  final bool isDark;
  const _Badge(
      {required this.label,
      required this.price,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
        Text(NumberFormatter.formatDecimal(price ?? 0),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final dynamic product;
  final bool isDark;
  final AppLocalizations l10n;
  const _StockBadge(
      {required this.product, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final qty = product['quantity']?.toDouble() ?? 0.0;
    final isLow = qty <= (product['minThreshold'] ?? 0);
    final color = isLow ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_rounded, size: 14, color: color),
          4.width,
          Text('$qty ${product['unitName'] ?? l10n.piece}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  final Color primaryColor;
  const _EmptyView({required this.l10n, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 100, color: primaryColor.withOpacity(0.3)),
          20.height,
          Text(l10n.noProducts,
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const _ErrorView(
      {required this.message, required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          16.height,
          ElevatedButton(onPressed: onRetry, child: Text(l10n.loading)),
        ],
      ),
    );
  }
}
