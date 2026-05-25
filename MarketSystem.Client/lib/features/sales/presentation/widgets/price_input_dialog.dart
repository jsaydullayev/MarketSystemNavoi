import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
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
    _commentController = TextEditingController(
      text: widget.product['comment'] ?? '',
    );

    _showMinPrice = _minPrice > 0 && currentPrice < _minPrice;
    _priceController.addListener(_onPriceChanged);
  }

  String _formatNumber(double value) {
    final unitName = (widget.product['unitName'] ?? '')
        .toString()
        .toLowerCase();
    const weightUnits = ['kg', 'кг', 'kilogram', 'g', 'gr', 'litr', 'l', 'л'];
    final isWeight = weightUnits.contains(unitName);

    if (!isWeight && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void _onPriceChanged() {
    final cleanText = _priceController.text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
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

  /// AUDIT-3 — upper bound on price/qty so a paste like `999999999999.99`
  /// can't reach the backend's `decimal(18,2)` column and overflow, and
  /// so a fat-finger `100000000` doesn't show up as the sale total in
  /// the daily report. 999_999_999 covers any realistic UZS line item
  /// (~$80k USD at 2026 rates); larger values are almost certainly typos.
  static const double _maxAmount = 999999999;

  void _submit() {
    final cleanPriceText = _priceController.text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
    final cleanQtyText = _qtyController.text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');

    final price = double.tryParse(cleanPriceText) ?? 0;
    final rawQty = double.tryParse(cleanQtyText) ?? 1;

    // AUDIT-3 — refuse out-of-range / non-finite values before they
    // leave the widget. The product-edit chip used to surface a raw
    // FormatException; now we just keep the sheet open so the user can
    // correct the input.
    if (price < 0 ||
        price > _maxAmount ||
        rawQty <= 0 ||
        rawQty > _maxAmount ||
        !price.isFinite ||
        !rawQty.isFinite) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorOccurred),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // BUG FIX: Remove truncation - allow decimal quantities for all units.
    final double qty = rawQty;

    widget.onConfirm(price, qty, _commentController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitName = widget.product['unitName'] ?? l10n.piece;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl2),
          ),
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

            // Product header
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
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      widget.product['name'] ?? l10n.unknown,
                      style: AppTextStyles.titleMedium(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Qty + Price
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    context: context,
                    controller: _qtyController,
                    label: l10n.amount,
                    icon: Icons.add_box_outlined,
                    suffix: unitName,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 3,
                  child: _buildField(
                    context: context,
                    controller: _priceController,
                    label: l10n.price,
                    icon: Icons.payments_outlined,
                    suffix: l10n.currencySom,
                    isNum: true,
                  ),
                ),
              ],
            ),

            // Min price warning
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showMinPrice
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
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${l10n.minPrice}: ${NumberFormatter.format(_minPrice)}',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Comment
            _buildField(
              context: context,
              controller: _commentController,
              label: l10n.reasonOptional,
              icon: Icons.edit_note,
              isNum: false,
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
                  child: AppPrimaryButton(label: l10n.add, onPressed: _submit),
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
          style: AppTextStyles.bodyLarge().copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
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
              borderSide: BorderSide(color: context.colors.brand, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.xl),
          ),
        ),
      ],
    );
  }
}
