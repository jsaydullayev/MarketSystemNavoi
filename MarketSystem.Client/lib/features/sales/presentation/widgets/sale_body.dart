import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/extensions/app_extensions.dart';

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
  final VoidCallback onAddExternalProduct;  // ✅ Tashqi mahsulot qo'shish funksiyasi

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
    required this.onAddExternalProduct,  // ✅ Tashqi mahsulot qo'shish funksiyasi
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
        Expanded(
          child: Column(
            children: [
              // ✅ Tashqi mahsulot tugmasi (Product grid yuqorisida)
              Row(
                children: [
                  Expanded(
                    child: _buildProductGrid(isDark, l10n, theme),
                  ),
                  // Tashqi mahsulot qo'shish tugmasi
                  _buildExternalProductButton(isDark, l10n),
                ],
              ),
            ],
          ),
        ),
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
          final isExternal = item['isExternal'] ?? false;  // ✅ Tashqi mahsulot flag

          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isExternal
                  ? Colors.orange.withOpacity(0.08)  // ✅ Tashqi mahsulot uchun rang
                  : AppColors.getCard(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isExternal
                      ? Colors.orange.withOpacity(0.3)
                      : theme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['productName'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isExternal ? Colors.orange.shade700 : (isDark ? Colors.white : const Color(0xFF1F2937)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isExternal)
                      const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFEF4444)),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item['quantity']} × ${NumberFormatter.format(item['salePrice'])}",
                        style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    // ✅ Tashqi mahsulotlar uchun edit tugmasi yo'q
                    if (!isExternal)
                      GestureDetector(
                        onTap: () => onEditPrice(index, item),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.edit_rounded, size: 11, color: Color(0xFF3B82F6)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isExternal)
                  _buildQtyButton(icon: Icons.remove_rounded, onTap: () => onRemoveFromCart(index)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isExternal
                        ? "${item['quantity']}"
                        : "${item['quantity'] % 1 == 0 ? (item['quantity'] as num).toInt() : item['quantity']}",
                    style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isExternal ? Colors.orange.shade700 : (isDark ? Colors.white : const Color(0xFF1F2937)),
                        ),
                  ),
                ),
                if (!isExternal)
                  _buildQtyButton(icon: Icons.add_rounded, onTap: () => onUpdateQuantity(index, (item['quantity'] as num).toDouble() + 1)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: const Color(0xFF3B82F6)),
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
    bool isDark,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
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
        final isInStock = stock > 0;
        final isLow = stock > 0 && stock <= 5;

        final stockColor = isLow
            ? Colors.orange
            : isInStock
                ? const Color(0xFF10B981)
                : Colors.grey;

        return InkWell(
          onTap: isInStock ? () => onAddToCart(p) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E)
                  : isInStock
                      ? Colors.white
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE5E7EB)),
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
                    style: TextStyle(
                        fontSize: 10,
                        color: isInStock
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold)),
                // Qoldiq + Tugma
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Qoldiq
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stockColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        4.width,
                        Text(
                          stock.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Tugma (faqat oddiy mahsulot uchun)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.add_rounded, size: 15, color: const Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Tashqi mahsulot qo'shish tugmasi
  Widget _buildExternalProductButton(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAddExternalProduct,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),  // Light
                  Colors.orange.withOpacity(0.05),  // Dark
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Tashqi mahsulot uchun ikon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,  // Business icon for external products
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                8.width,
                Text(
                  l10n.addExternalProduct,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
