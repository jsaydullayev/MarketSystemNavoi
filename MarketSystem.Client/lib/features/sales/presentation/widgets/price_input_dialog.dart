import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';

class PriceInputSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(double price, double qty, String? comment) onConfirm;

  const PriceInputSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> product,
    required Function(double price, double qty, String? comment) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PriceInputSheet(product: product, onConfirm: onConfirm),
    );
  }

  @override
  State<PriceInputSheet> createState() => _PriceInputSheetState();
}

class _PriceInputSheetState extends State<PriceInputSheet> {
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _commentController;

  double _minPrice = 0.0;
  bool _showMinPrice = false;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.product['minSalePrice']?.toDouble() ?? 0.0;

    final currentPrice = widget.product['salePrice']?.toDouble() ?? 0.0;
    final initialQty = widget.product['initialQuantity']?.toDouble() ?? 1.0;

    _priceController = TextEditingController(text: _formatNumber(currentPrice));
    _qtyController = TextEditingController(text: _formatNumber(initialQty));
    _commentController =
        TextEditingController(text: widget.product['comment'] ?? '');

    _showMinPrice = _minPrice > 0 && currentPrice < _minPrice;
    _priceController.addListener(_onPriceChanged);
  }

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }

  void _onPriceChanged() {
    final cleanText = _priceController.text.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
    final price = double.tryParse(cleanText) ?? 0.0;
    final shouldShow = _minPrice > 0 && price < _minPrice;
    if (shouldShow != _showMinPrice) {
      setState(() => _showMinPrice = shouldShow);
    }
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _priceController.dispose();
    _qtyController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final cleanPriceText = _priceController.text.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
    final cleanQtyText = _qtyController.text.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
    
    final price = double.tryParse(cleanPriceText) ?? 0;
    final qty = double.tryParse(cleanQtyText) ?? 1;
    widget.onConfirm(price, qty, _commentController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final unitName = widget.product['unitName'] ?? l10n.piece;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCard(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.product['name'] ?? l10n.unknown,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Qty + Price
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _qtyController,
                    label: l10n.amount,
                    icon: Icons.add_box_outlined,
                    suffix: unitName,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildField(
                    controller: _priceController,
                    label: l10n.price,
                    icon: Icons.payments_outlined,
                    suffix: l10n.currencySom,
                    isNum: true,
                  ),
                ),
              ],
            ),

            // Min narx ogohlantirish
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showMinPrice
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            "${l10n.minPrice}: ${NumberFormatter.format(_minPrice)}",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Comment
            _buildField(
              controller: _commentController,
              label: l10n.reasonOptional,
              icon: Icons.edit_note,
              isNum: false,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
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
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    bool isNum = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
        ),
        TextField(
          controller: controller,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            suffixText: suffix,
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
