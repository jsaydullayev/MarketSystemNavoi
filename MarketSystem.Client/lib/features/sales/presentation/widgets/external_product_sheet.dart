import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// External Product Sheet - Tashqi mahsulot kiritish dialogi.
/// PriceInputSheet ga o'xshash dizaynda, tashqi mahsulot uchun.
class ExternalProductSheet extends StatefulWidget {
  final Function(
    String name,
    double costPrice,
    double qty,
    double salePrice,
    String? comment,
  ) onConfirm;

  const ExternalProductSheet({
    super.key,
    required this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required Function(
      String name,
      double costPrice,
      double qty,
      double salePrice,
      String? comment,
    ) onConfirm,
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
    final costPrice =
        double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0;
    final qty =
        double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    final salePrice =
        double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0;

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

    widget.onConfirm(
      name,
      costPrice,
      qty,
      salePrice,
      _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl2)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2,
          AppSpacing.lg,
          AppSpacing.xl2,
          AppSpacing.xl3,
        ),
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
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.brand,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      l10n.addExternalProduct,
                      style: AppTextStyles.titleMedium(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Product name
            _buildField(
              context: context,
              controller: _nameController,
              label: l10n.externalProductName,
              icon: Icons.description_rounded,
              isNum: false,
              hintText: 'Masalan: Xizmat',
            ),

            const SizedBox(height: AppSpacing.lg),

            // Cost price + qty
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    context: context,
                    controller: _costPriceController,
                    label: l10n.externalCostPrice,
                    icon: Icons.inventory_2_rounded,
                    suffix: l10n.currencySom,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: _buildField(
                    context: context,
                    controller: _qtyController,
                    label: l10n.amount,
                    icon: Icons.add_box_outlined,
                    isNum: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sale price
            _buildField(
              context: context,
              controller: _salePriceController,
              label: l10n.salePrice,
              icon: Icons.payments_outlined,
              suffix: l10n.currencySom,
              isNum: true,
            ),

            // Validation error
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showValidationError
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        left: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _validationError,
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Comment
            _buildField(
              context: context,
              controller: _commentController,
              label: l10n.reasonOptional,
              icon: Icons.edit_note,
              isNum: false,
              maxLines: 2,
            ),

            const SizedBox(height: AppSpacing.xl3),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.cancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    label: "Qo'shish",
                    onPressed: _validateAndSubmit,
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
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    bool isNum = false,
    String? hintText,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          maxLines: maxLines,
          style: AppTextStyles.bodyLarge().copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textMuted,
            ),
            prefixIcon: Icon(icon, size: 20, color: context.colors.brand),
            suffixText: suffix,
            suffixStyle: AppTextStyles.bodySmall(),
            filled: true,
            fillColor: context.colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(
                color: context.colors.brand,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.xl),
          ),
        ),
      ],
    );
  }
}
