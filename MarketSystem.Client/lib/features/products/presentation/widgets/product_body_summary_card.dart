// Products body — summary card.
//
// 3-cell summary card showing total count, low-stock count, and out-of-stock
// count. Extracted from `product_body.dart` as part of a code-move refactor.

import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// 3-cell summary card showing total count, low-stock count, and out-of-stock
/// count. Numeric values turn warning yellow / danger red. Demo class
/// `.prod-summary`.
class ProductSummaryCard extends StatelessWidget {
  final int total;
  final int lowStock;
  final int outOfStock;
  final AppLocalizations l10n;

  const ProductSummaryCard({
    super.key,
    required this.total,
    required this.lowStock,
    required this.outOfStock,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              value: total.toString(),
              label: l10n.totalShort,
              valueColor: context.colors.text,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              value: lowStock.toString(),
              label: l10n.lowStockShort,
              valueColor: AppColors.warning,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              value: outOfStock.toString(),
              label: l10n.outOfStockShort,
              valueColor: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _SummaryCell({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: context.colors.border);
  }
}
