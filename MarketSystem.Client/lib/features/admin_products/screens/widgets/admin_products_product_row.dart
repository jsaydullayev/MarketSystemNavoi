import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';

import '../../../../l10n/app_localizations.dart';

/// Single product card. Demo's `.prod-row` inside `id="page-prod-list"`.
class AdminProductsProductRow extends StatelessWidget {
  final dynamic product;
  final String? userRole;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminProductsProductRow({
    super.key,
    required this.product,
    required this.userRole,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qty = (product['quantity'] as num?)?.toDouble() ?? 0;
    final minThreshold = (product['minThreshold'] as num?)?.toDouble() ?? 0;
    final isOut = qty <= 0;
    final isLow = !isOut && qty <= minThreshold;
    final unitName = product['unitName'] ?? l10n.piece;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / icon tile
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: context.colors.brandDark,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Name, category, badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? l10n.unknown,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.salePriceLabel(product['salePrice'] ?? 0),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.costPriceLabel(product['costPrice'] ?? 0),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (product['isTemporary'] == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _Pill(
                      label: l10n.temporary,
                      color: context.colors.brandDark,
                      bg: context.colors.brandLight,
                    ),
                  ),
                if (isLow)
                  _Pill(
                    label: l10n.lowStockWarning(product['minThreshold'] ?? 0),
                    color: AppColors.warning,
                    bg: AppColors.warningLight,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Price + stock + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.format(
                  (product['salePrice'] as num?)?.toDouble() ?? 0,
                ),
                style: AppTextStyles.bodyLarge().copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.brand,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isOut
                    ? 'Tugadi'
                    : 'Stok: ${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2)} $unitName',
                style: AppTextStyles.bodySmall().copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOut
                      ? AppColors.danger
                      : (isLow
                            ? AppColors.warning
                            : context.colors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAction(
                    icon: Icons.edit_outlined,
                    color: context.colors.brand,
                    onTap: onEdit,
                    tooltip: l10n.edit,
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    onTap: onDelete,
                    tooltip: l10n.delete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  const _Pill({
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: 10,
              letterSpacing: 0.4,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
