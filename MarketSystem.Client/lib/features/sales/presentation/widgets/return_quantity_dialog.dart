import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ReturnQuantityDialog extends StatefulWidget {
  final String productName;
  final double maxQuantity;

  const ReturnQuantityDialog({
    super.key,
    required this.productName,
    required this.maxQuantity,
  });

  @override
  State<ReturnQuantityDialog> createState() => _ReturnQuantityDialogState();
}

class _ReturnQuantityDialogState extends State<ReturnQuantityDialog> {
  late TextEditingController _controller;
  double _returnQty = 1.0;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _returnQty = parsed;
      _isValid = parsed > 0 && parsed <= widget.maxQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2)),
      backgroundColor: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sarlavha
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.assignment_return_rounded,
                      color: AppColors.danger, size: 20),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.returnProduct,
                        style: AppTextStyles.titleMedium()
                            .copyWith(fontSize: 16),
                      ),
                      Text(
                        widget.productName,
                        style: AppTextStyles.bodySmall(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Mavjud miqdor
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.availableQuantity,
                      style: AppTextStyles.bodySmall()),
                  Text(
                    '${widget.maxQuantity % 1 == 0 ? widget.maxQuantity.toInt() : widget.maxQuantity}',
                    style: AppTextStyles.labelLarge().copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Input
            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTextStyles.bodyLarge(),
              decoration: InputDecoration(
                labelText: l10n.returnQuantity,
                labelStyle: AppTextStyles.bodyMedium()
                    .copyWith(color: context.colors.textSecondary),
                errorText: _isValid ? null : l10n.invalidQuantity,
                filled: true,
                fillColor: context.colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide:
                      BorderSide(color: context.colors.brand, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                      color: AppColors.danger, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Tugmalar
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.cancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppDangerButton(
                    label: l10n.returnAction,
                    onPressed:
                        _isValid ? () => Navigator.pop(context, _returnQty) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
