import 'package:flutter/material.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'sale_receipt_painter.dart';

class SaleReceiptCard extends StatelessWidget {
  const SaleReceiptCard({
    super.key,
    required this.items,
    required this.total,
    required this.paid,
    required this.remaining,
  });

  final List<dynamic> items;
  final double total;
  final double paid;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: CustomPaint(
        painter: SaleReceiptPainter(
          color: context.colors.border,
          radius: AppRadius.lg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                  8.width,
                  Text(
                    l10n.products,
                    style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
                  ),
                  const Spacer(),
                  Text('${items.length}', style: AppTextStyles.labelSmall()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...items.map((item) => _line(context, item, l10n)),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: context.colors.border),
              const SizedBox(height: AppSpacing.lg),
              _totalsRow(
                context,
                l10n.totalSum,
                NumberFormatter.format(total),
                emphasize: false,
              ),
              const SizedBox(height: AppSpacing.md),
              _totalsRow(
                context,
                l10n.paid,
                NumberFormatter.format(paid),
                emphasize: true,
                valueColor: AppColors.success,
              ),
              if (remaining > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _totalsRow(
                  context,
                  l10n.debt,
                  NumberFormatter.format(remaining),
                  emphasize: false,
                  valueColor: AppColors.danger,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    Map<String, dynamic> item,
    AppLocalizations l10n,
  ) {
    final qty = (item['quantity'] as num).toDouble();
    final price = (item['salePrice'] as num).toDouble();
    final isExternal = item['isExternal'] == true;
    final comment = (item['comment'] as String?)?.trim() ?? '';

    final unitName = (item['unit'] ?? '').toString().toLowerCase();
    const weightUnits = ['kg', 'кг', 'kilogram', 'g', 'gr', 'litr', 'l', 'л'];
    final isWeight = weightUnits.contains(unitName);
    final qtyDisplay = isWeight ? qty.toString() : qty.toInt().toString();
    final unit = item['unit'] ?? l10n.piece;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item['productName'] ?? l10n.unknown,
                            style: AppTextStyles.labelLarge().copyWith(
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExternal) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandTint,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              l10n.externalTag,
                              style: AppTextStyles.caption().copyWith(
                                color: context.colors.brandDark,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qtyDisplay $unit × ${NumberFormatter.format(price)}',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                NumberFormatter.format(item['totalPrice']),
                style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 13,
                    color: context.colors.brandDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      comment,
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.colors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalsRow(
    BuildContext context,
    String label,
    String value, {
    required bool emphasize,
    Color? valueColor,
  }) {
    final labelStyle = emphasize
        ? AppTextStyles.labelLarge()
        : AppTextStyles.bodyMedium().copyWith(
            color: context.colors.textSecondary,
          );
    final valueStyle = emphasize
        ? AppTextStyles.titleMedium().copyWith(
            color: valueColor ?? context.colors.text,
            fontSize: 16,
          )
        : AppTextStyles.bodyMedium().copyWith(
            color: valueColor ?? context.colors.text,
            fontWeight: FontWeight.w700,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}
