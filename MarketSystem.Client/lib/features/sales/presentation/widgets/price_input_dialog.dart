import 'package:flutter/material.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';

class PriceInputDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(double price, double qty, String? comment) onConfirm;

  const PriceInputDialog({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<PriceInputDialog> {
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    final currentPrice = widget.product['salePrice']?.toDouble() ?? 0.0;
    final initialQty = widget.product['initialQuantity']?.toDouble() ?? 1.0;

    _priceController = TextEditingController(text: currentPrice.toString());
    _qtyController = TextEditingController(text: initialQty.toString());
    _commentController =
        TextEditingController(text: widget.product['comment'] ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final minPrice = widget.product['minSalePrice']?.toDouble() ?? 0.0;
    final unitName = widget.product['unitName'] ?? l10n.piece;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCard(isDark),
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.shopping_bag_outlined,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.product['name'] ?? l10n.unknown,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildStyledField(
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
                    child: _buildStyledField(
                      controller: _priceController,
                      label: l10n.price,
                      icon: Icons.payments_outlined,
                      suffix: l10n.currencySom,
                      isNum: true,
                    ),
                  ),
                ],
              ),
              if (minPrice > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "${l10n.minPrice}: ${NumberFormatter.format(minPrice)}",
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              16.height,
              _buildStyledField(
                controller: _commentController,
                label: l10n.reasonOptional,
                icon: Icons.edit_note,
                isNum: false,
              ),
              32.height,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel,
                          style: TextStyle(color: theme.hintColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final p = double.tryParse(_priceController.text) ?? 0;
                        final q = double.tryParse(_qtyController.text) ?? 1;
                        widget.onConfirm(p, q, _commentController.text);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.add,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledField({
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
