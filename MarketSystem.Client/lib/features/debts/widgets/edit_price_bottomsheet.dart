import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class EditPriceBottomSheet extends StatefulWidget {
  final dynamic saleItem;
  final String debtStatus;
  final String? userRole;
  final Future<void> Function(double newPrice, String comment) onSave;

  const EditPriceBottomSheet({
    super.key,
    required this.saleItem,
    required this.debtStatus,
    required this.userRole,
    required this.onSave,
  });

  @override
  State<EditPriceBottomSheet> createState() => _EditPriceBottomSheetState();
}

class _EditPriceBottomSheetState extends State<EditPriceBottomSheet> {
  late final TextEditingController _priceController;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final price = (widget.saleItem['salePrice'] as num).toDouble();
    _priceController = TextEditingController(
      text: price == price.truncateToDouble()
          ? price.toInt().toString()
          : price.toString(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _errorMessage = null);

    final newPrice =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final comment = _commentController.text.trim();

    if (newPrice <= 0) {
      setState(() => _errorMessage = l10n.priceMustBePositive);
      return;
    }
    if (comment.isEmpty) {
      setState(() => _errorMessage = l10n.commentRequiredError);
      return;
    }

    final ok = await _showConfirmDialog(newPrice);
    if (ok != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSave(newPrice, comment);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorParser.parse(e.toString());
      });
    }
  }

  Future<bool?> _showConfirmDialog(double newPrice) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(l10n.confirm, style: AppTextStyles.titleMedium()),
        content: Text(
          l10n.confirmPriceChangeDesc(NumberFormatter.formatDecimal(newPrice)),
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text(l10n.yesConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isClosed = widget.debtStatus == 'Closed';
    final productName = widget.saleItem['productName'] ?? l10n.product;
    final quantity = widget.saleItem['quantity'];
    final oldPrice = (widget.saleItem['salePrice'] as num).toDouble();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.xl,
        AppSpacing.xl2,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl3,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: AppColors.brand, size: 20),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(l10n.editPriceTitle, style: AppTextStyles.titleMedium()),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: AppColors.brand, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.md + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName,
                            style: AppTextStyles.bodyMedium()
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          l10n.productQuantityAndOldPrice(quantity,
                              NumberFormatter.formatDecimal(oldPrice)),
                          style: AppTextStyles.bodySmall().copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.newPriceLabel.toUpperCase(),
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
              onChanged: (_) => setState(() => _errorMessage = null),
              decoration: InputDecoration(
                hintText: l10n.priceWithCurrency,
                hintStyle: AppTextStyles.bodyMedium().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
                prefixIcon:
                    const Icon(Icons.money_rounded, color: AppColors.brand),
                suffixText: l10n.currencySom,
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide:
                      const BorderSide(color: AppColors.brand, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.commentRequiredLabel.toUpperCase(),
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
              onChanged: (_) => setState(() => _errorMessage = null),
              decoration: InputDecoration(
                hintText: l10n.exampleComment,
                hintStyle: AppTextStyles.bodyMedium().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.all(AppSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide:
                      const BorderSide(color: AppColors.brand, width: 1.5),
                ),
              ),
            ),
            if (isClosed) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.closedDebtAudit,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.danger, size: 16),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl2),
            AppPrimaryButton(
              label: l10n.save,
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
