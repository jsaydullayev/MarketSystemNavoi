import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// External Product Sheet - Tashqi mahsulot kiritish dialogi
/// PriceInputSheet ga o'xshash dizaynda, lekin tashqi mahsulot uchun mo'ljallangan
class ExternalProductSheet extends StatefulWidget {
  final Function(String name, double costPrice, double qty, double salePrice, String? comment) onConfirm;

  const ExternalProductSheet({
    super.key,
    required this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required Function(String name, double costPrice, double qty, double salePrice, String? comment) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExternalProductSheet(onConfirm: onConfirm),
    );
  }

  @override
  State<ExternalProductSheet> createState() => _ExternalProductSheetState();
}

class _ExternalProductSheetState extends State<ExternalProductSheet> {
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _qtyController;
  late TextEditingController _salePriceController;
  late TextEditingController _commentController;

  bool _showValidationError = false;
  String _validationError = '';

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _costPriceController = TextEditingController(text: '0');
    _qtyController = TextEditingController(text: '1');
    _salePriceController = TextEditingController(text: '0');
    _commentController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _qtyController.dispose();
    _salePriceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final costPrice = double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0;
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0;

    // Validatsiyalar
    if (name.isEmpty) {
      setState(() {
        _showValidationError = true;
        _validationError = l10n.externalProductNameRequired;
      });
      return;
    }

    if (costPrice <= 0) {
      setState(() {
        _showValidationError = true;
        _validationError = l10n.externalCostPriceRequired;
      });
      return;
    }

    if (costPrice >= salePrice) {
      setState(() {
        _showValidationError = true;
        _validationError = l10n.externalCostPriceGreaterThanSalePrice;
      });
      return;
    }

    if (qty <= 0) {
      setState(() {
        _showValidationError = true;
        _validationError = l10n.quantityMustBePositive;
      });
      return;
    }

    // Validatsiya o'tdi - submit
    widget.onConfirm(
      name,
      costPrice,
      qty,
      salePrice,
      _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orangeColor = AppColors.orangePrimary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCard(theme.brightness == Brightness.dark),
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

            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: orangeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: orangeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.addExternalProduct,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product Name
            _buildField(
              controller: _nameController,
              label: l10n.externalProductName,
              icon: Icons.description_rounded,
              isNum: false,
              hintText: 'Masalan: Xizmat',
              orangeColor: orangeColor,
            ),

            const SizedBox(height: 12),

            // Cost Price + Quantity (horizontal)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _costPriceController,
                    label: l10n.externalCostPrice,
                    icon: Icons.inventory_2_rounded,
                    suffix: l10n.currencySom,
                    isNum: true,
                    orangeColor: orangeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _qtyController,
                    label: l10n.amount,
                    icon: Icons.add_box_outlined,
                    isNum: true,
                    orangeColor: orangeColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sale Price
            _buildField(
              controller: _salePriceController,
              label: l10n.salePrice,
              icon: Icons.payments_outlined,
              suffix: l10n.currencySom,
              isNum: true,
              orangeColor: orangeColor,
            ),

            // Validation error message
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showValidationError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: orangeColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _validationError,
                              style: TextStyle(
                                fontSize: 12,
                                color: orangeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),

            // Comment
            _buildField(
              controller: _commentController,
              label: l10n.reasonOptional,
              icon: Icons.edit_note,
              isNum: false,
              maxLines: 2,
              orangeColor: orangeColor,
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
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _validateAndSubmit,
                    child: Text(
                      "Qo'shish",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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
    String? hintText,
    int? maxLines = 1,
    required Color orangeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: 20, color: orangeColor),
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
              borderSide: BorderSide(color: orangeColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
