import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  const DebtCard({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final totalDebt = (debt['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (debt['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final status = debt['status']?.toString() ?? 'Open';
    final createdAt = debt['createdAt'];
    final saleItems = debt['saleItems'] as List<dynamic>?;
    final l10n = AppLocalizations.of(context)!;

    final formattedDate =
        NumberFormatter.formatDateTime(createdAt, showTime: true);

    final isOpen = status.toLowerCase() == 'open';
    final hasProducts = saleItems != null && saleItems.isNotEmpty;
    final accent = isOpen ? AppColors.danger : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: AppTextStyles.bodySmall()
                    .copyWith(color: AppColors.textSecondary, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen ? Icons.money_off : Icons.check_circle,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      isOpen ? l10n.inDebt : l10n.completed,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _BuildAmountColumn(
                  label: l10n.totalSum,
                  amount: totalDebt,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _BuildAmountColumn(
                  label: l10n.remainingDebt,
                  amount: remainingDebt,
                  color: accent,
                  isMain: true,
                ),
              ),
            ],
          ),
          if (hasProducts) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.borderSoft, height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.shopping_cart,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${l10n.products} (${saleItems.length})',
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  NumberFormatter.formatTime(createdAt),
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...saleItems.map((item) => _BuildSaleItem(item: item)),
          ] else if (!hasProducts && isOpen) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                l10n.noProductsFound,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuildSaleItem extends StatelessWidget {
  final dynamic item;
  const _BuildSaleItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productName = item['productName']?.toString() ?? l10n.unknownProduct;
    final quantity = item['quantity'] as num? ?? 0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final comment = item['comment']?.toString();

    final quantityDisplay = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md - 2),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 16,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$quantityDisplay ${l10n.piece}',
                        style: AppTextStyles.bodySmall().copyWith(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '× ${NumberFormatter.format(salePrice)}',
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment,
                    style: AppTextStyles.bodySmall().copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.format(totalPrice),
                style: AppTextStyles.bodyMedium().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.currencySom,
                style: AppTextStyles.caption().copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildAmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isMain;
  const _BuildAmountColumn({
    required this.label,
    required this.amount,
    required this.color,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          NumberFormatter.format(amount),
          style: AppTextStyles.titleMedium().copyWith(
            fontSize: isMain ? 18 : 15,
            color: color,
          ),
        ),
      ],
    );
  }
}
