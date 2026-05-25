import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/sales_bloc.dart';

/// Picker sheet: lets the user choose which item to return.
/// After selection, opens [showReturnBottomSheet] for that item.
void showRefundPicker(
  BuildContext context,
  List<dynamic> items,
  String saleId,
) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _warningBanner(context, l10n.returnWarning),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.whichProductReturning, style: AppTextStyles.caption()),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final item = items[i] as Map<String, dynamic>;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    showReturnBottomSheet(context, item, saleId);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.colors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName']?.toString() ?? l10n.unknown,
                                style: AppTextStyles.labelLarge().copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.soldQtyFormat(
                                  item['quantity'],
                                  NumberFormatter.format(item['salePrice']),
                                ),
                                style: AppTextStyles.bodySmall(),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Full return form: quantity, reason pills, refund method, confirmation.
void showReturnBottomSheet(
  BuildContext context,
  Map<String, dynamic> item,
  String saleId,
) {
  final l10n = AppLocalizations.of(context)!;
  final productName = item['productName'] ?? l10n.unknownProduct;
  final saleItemId = item['id']?.toString() ?? '';
  final maxQuantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
  final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;

  final quantityController = TextEditingController(text: '1');
  final commentController = TextEditingController();
  String selectedReason = l10n.returnReasonBad;
  String selectedMethod = 'cash';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final qtyText = quantityController.text
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll(',', '.');
        final currentQty = double.tryParse(qtyText) ?? 0.0;
        final returnSum = currentQty * salePrice;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            top: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
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
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                20.height,
                Row(
                  children: [
                    const Icon(
                      Icons.keyboard_return_rounded,
                      color: AppColors.danger,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Text(
                      l10n.processReturn,
                      style: AppTextStyles.titleMedium(),
                    ),
                  ],
                ),
                16.height,
                _warningBanner(context, l10n.returnWarning),
                16.height,
                Text(
                  productName,
                  style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
                ),
                4.height,
                Text(
                  '${l10n.maxReturn}: $maxQuantity ${l10n.piece}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.warning,
                  ),
                ),
                16.height,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _fieldLabel(
                        l10n.amount,
                        TextField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setSheetState(() {}),
                          decoration: _inputStyle(
                            context,
                            '1',
                            suffix: l10n.piece,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                16.height,
                Text(l10n.reasonLabel, style: AppTextStyles.caption()),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children:
                      [
                        l10n.returnReasonBad,
                        l10n.returnReasonExpired,
                        l10n.returnReasonDisliked,
                        l10n.returnReasonOther,
                      ].map((reason) {
                        final sel = selectedReason == reason;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedReason = reason),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? context.colors.text
                                  : context.colors.inputFill,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              reason,
                              style: AppTextStyles.labelSmall().copyWith(
                                color: sel ? Colors.white : context.colors.text,
                                fontSize: 12,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                16.height,
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  decoration: _inputStyle(context, l10n.additionalCommentHint),
                ),
                16.height,
                Text(l10n.returnMethodLabel, style: AppTextStyles.caption()),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _methodTile(
                        context,
                        icon: Icons.payments_outlined,
                        title: l10n.cashReturn,
                        subtitle: l10n.toCustomerHere,
                        selected: selectedMethod == 'cash',
                        onTap: () =>
                            setSheetState(() => selectedMethod = 'cash'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _methodTile(
                        context,
                        icon: Icons.assignment_outlined,
                        title: l10n.toBalance,
                        subtitle: l10n.forNextSale,
                        selected: selectedMethod == 'balance',
                        onTap: () =>
                            setSheetState(() => selectedMethod = 'balance'),
                      ),
                    ),
                  ],
                ),
                16.height,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.toReturnLabel,
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormatter.format(returnSum)} UZS',
                        style: AppTextStyles.displayMedium().copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                16.height,
                AppDangerButton(
                  label: l10n.confirmAndReturn,
                  icon: Icons.keyboard_return_rounded,
                  onPressed: () {
                    final parsed = double.tryParse(qtyText);
                    if (parsed == null || parsed <= 0 || parsed > maxQuantity) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(l10n.invalidQuantity),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final note = commentController.text.trim();
                    final combined = note.isEmpty
                        ? selectedReason
                        : '$selectedReason — $note';
                    context.read<SalesBloc>().add(
                      ReturnSaleItemEvent(
                        saleId: saleId,
                        saleItemId: saleItemId,
                        quantity: parsed,
                        comment: combined,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppSecondaryButton(
                  label: l10n.cancel,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _warningBanner(BuildContext context, String message) {
  return Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.warningLight,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: const Border(
        left: BorderSide(color: AppColors.warning, width: 3),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

Widget _methodTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: selected ? context.colors.brandLight : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? context.colors.brand : context.colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.brand, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.labelLarge().copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.bodySmall()),
        ],
      ),
    ),
  );
}

Widget _fieldLabel(String label, Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.labelSmall()),
      8.height,
      child,
    ],
  );
}

InputDecoration _inputStyle(
  BuildContext context,
  String hint, {
  String? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium().copyWith(
      color: context.colors.textMuted,
    ),
    suffixText: suffix,
    suffixStyle: AppTextStyles.bodySmall(),
    filled: true,
    fillColor: context.colors.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg,
    ),
  );
}
