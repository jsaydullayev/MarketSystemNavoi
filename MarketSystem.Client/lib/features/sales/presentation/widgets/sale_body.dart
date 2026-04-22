import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';

class SaleBody extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> filteredProducts;
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? selectedCustomer;
  final double totalAmount;
  final VoidCallback onSelectCustomer;
  final Function(dynamic) onAddToCart;
  final Function(int, double) onUpdateQuantity;
  final Function(int) onRemoveFromCart;
  final Function(int, Map<String, dynamic>) onEditPrice;
  final TextEditingController searchController;

  const SaleBody({
    super.key,
    required this.isLoading,
    required this.filteredProducts,
    required this.cartItems,
    required this.selectedCustomer,
    required this.totalAmount,
    required this.onSelectCustomer,
    required this.onAddToCart,
    required this.onUpdateQuantity,
    required this.onRemoveFromCart,
    required this.onEditPrice,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildTopSection(isDark, l10n, theme),
        if (cartItems.isNotEmpty) _buildCartList(isDark, l10n, theme),
        _buildSearchField(isDark, l10n),
        Expanded(child: _buildProductGrid(isDark, l10n, theme)),
      ],
    );
  }

  Widget _buildTopSection(bool isDark, AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onSelectCustomer,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border:
                    Border.all(color: isDark ? Colors.white10 : Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded,
                      color: theme.primaryColor),
                  12.width,
                  Text(
                    selectedCustomer?['fullName'] ?? l10n.customerNotSelected,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
          12.height,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.totalSum,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  NumberFormatter.format(totalAmount),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(bool isDark, AppLocalizations l10n, ThemeData theme) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.getCard(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['productName'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    InkWell(
                      onTap: () => onRemoveFromCart(index),
                      child:
                          const Icon(Icons.cancel, size: 18, color: Colors.red),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item['quantity']} ${l10n.piece}",
                        style: const TextStyle(fontSize: 11)),
                    InkWell(
                      onTap: () => onEditPrice(index, item),
                      child: Text(NumberFormatter.format(item['salePrice']),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: l10n.searchProduct,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: AppColors.getCard(isDark),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
      bool isDark, AppLocalizations l10n, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final p = filteredProducts[index];
        final stock = (p['quantity'] ?? 0).toDouble();

        return InkWell(
          onTap: () => onAddToCart(p),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getCard(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.inventory_2_rounded,
                      color: theme.primaryColor, size: 20),
                ),
                8.height,
                Text(p['name'] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                4.height,
                Text(NumberFormatter.format(p['salePrice']),
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
                Text("${l10n.warehouse}: $stock",
                    style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
        );
      },
    );
  }
}
