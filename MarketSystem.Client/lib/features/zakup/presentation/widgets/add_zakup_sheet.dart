import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import '../bloc/zakup_bloc.dart';
import '../bloc/events/zakup_event.dart';

class AddZakupSheet extends StatefulWidget {
  final List<dynamic> products;

  const AddZakupSheet({super.key, required this.products});

  static void show(BuildContext context, {required List<dynamic> products}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ZakupBloc>(),
        child: AddZakupSheet(products: products),
      ),
    );
  }

  @override
  State<AddZakupSheet> createState() => _AddZakupSheetState();
}

class _AddZakupSheetState extends State<AddZakupSheet> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  List<dynamic> _filtered = [];
  dynamic _selectedProduct;

  // Step: 0 = product select, 1 = qty+price
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.products;
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.products
          : widget.products
              .where((p) => (p['name'] ?? '').toLowerCase().contains(q))
              .toList();
    });
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _selectedProduct = product;
      _step = 1;
    });
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    final l10n = AppLocalizations.of(context)!;

    if (qty == null || qty <= 0 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAmountAndPrice),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<ZakupBloc>().add(CreateZakupEvent(
          productId: _selectedProduct['id'],
          quantity: qty.toDouble(),
          costPrice: price,
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151515) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _step == 0 ? _buildProductStep(isDark) : _buildPriceStep(isDark),
      ),
    );
  }

  Widget _buildProductStep(bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _Handle(),
        _SheetHeader(
          title: l10n.selectProduct,
          onClose: () => Navigator.pop(context),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchProduct,
              hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                  fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  size: 20),
              filled: true,
              fillColor:
                  isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Product list
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(l10n.productNotFound,
                      style: TextStyle(
                          color:
                              isDark ? Colors.white38 : Colors.grey.shade400)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
                    final qtyStr = qty == qty.truncateToDouble()
                        ? qty.toInt().toString()
                        : qty.toString();

                    return GestureDetector(
                      onTap: () => _selectProduct(p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.inventory_2_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] ?? l10n.unknown,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$qtyStr ${l10n.piece}  •  ${NumberFormatter.format(p['salePrice'] ?? 0)} ${l10n.currencySom}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPriceStep(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Handle(),
        _SheetHeader(
          title: l10n.zakup,
          onClose: () => Navigator.pop(context),
          onBack: () => setState(() => _step = 0),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected product chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.shopping_bag_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedProduct['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color:
                                isDark ? Colors.white : const Color(0xFF111111),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Qty + Price fields
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _qtyController,
                        label: l10n.number,
                        icon: Icons.layers_rounded,
                        isNum: true,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _priceController,
                        label: l10n.costPriceField,
                        icon: Icons.payments_rounded,
                        isNum: true,
                        isDark: isDark,
                        suffix: l10n.currencySom,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel,
                      style: TextStyle(color: theme.hintColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submit,
                  child: Text(l10n.add,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onBack;

  const _SheetHeader({
    required this.title,
    required this.onClose,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNum;
  final bool isDark;
  final String? suffix;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isNum,
    required this.isDark,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade500)),
        ),
        TextField(
          controller: controller,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111111)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            suffixText: suffix,
            filled: true,
            fillColor:
                isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}
