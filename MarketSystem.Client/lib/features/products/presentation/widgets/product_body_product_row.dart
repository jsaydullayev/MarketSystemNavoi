// Products body — single product row.
//
// The product row plus its small visual sub-parts (emoji tile, stock label,
// popular chip). Extracted from `product_body.dart` as part of a code-move
// refactor.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Single product row matching the demo's `.prod-row`. 12px radius, 1px
/// soft border, white surface, 48x48 emoji tile on the left, name + category
/// in the middle, price + stock on the right. Out-of-stock items fade.
class ProductRow extends StatelessWidget {
  final dynamic product;
  final AppLocalizations l10n;
  final Function(dynamic) onDelete;
  final Function(dynamic) onEdit;
  final Function(dynamic) onZakup;
  final bool isReadOnly;
  final bool canViewCostPrice;

  const ProductRow({
    super.key,
    required this.product,
    required this.l10n,
    required this.onDelete,
    required this.onEdit,
    required this.onZakup,
    required this.isReadOnly,
    required this.canViewCostPrice,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canZakup =
        authProvider.user?['role'] == 'Admin' ||
        authProvider.user?['role'] == 'Owner';

    final qty = (product['quantity'] as num?)?.toDouble() ?? 0.0;
    final minThreshold = (product['minThreshold'] as num?)?.toDouble() ?? 0.0;
    final isOut = qty <= 0;
    final isLow = !isOut && qty <= minThreshold;
    final isPopular =
        product['isPopular'] == true ||
        product['popular'] == true ||
        (product['salesCount'] is num && (product['salesCount'] as num) > 50);

    Widget row = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        border: Border.all(color: context.colors.borderSoft, width: 1),
      ),
      child: Row(
        children: [
          _EmojiTile(product: product),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        product['name']?.toString() ?? 'N/A',
                        style: AppTextStyles.bodySmall().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.text,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 6),
                      const _PopularChip(),
                    ],
                  ],
                ),
                if (product['categoryName'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product['categoryName'].toString(),
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 11,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      color: context.colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (canViewCostPrice && product['costPrice'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.costPrice}: ${NumberFormatter.format(product['costPrice'])}',
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 10,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                NumberFormatter.format(product['salePrice']),
                style: AppTextStyles.bodyMedium().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.brand,
                ),
              ),
              const SizedBox(height: 2),
              _StockLabel(
                qty: qty,
                unitName: product['unitName']?.toString() ?? l10n.piece,
                isLow: isLow,
                isOut: isOut,
                l10n: l10n,
              ),
            ],
          ),
          if (canZakup && !isReadOnly) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => onZakup(product),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                Icons.add_shopping_cart_rounded,
                size: 20,
                color: context.colors.brand,
              ),
              tooltip: l10n.zakup,
            ),
          ],
        ],
      ),
    );

    if (isOut) {
      row = Opacity(opacity: 0.55, child: row);
    }

    // Read-only sellers see static rows. Editors keep swipe-to-edit /
    // swipe-to-delete behavior so the rest of the CRUD flow stays intact.
    if (isReadOnly) {
      return row;
    }

    return Dismissible(
      key: Key('product_${product['id']}'),
      background: _buildSwipeBg(
        color: context.colors.brand,
        icon: Icons.edit_rounded,
        label: l10n.editAction,
        align: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBg(
        color: AppColors.danger,
        icon: Icons.delete_forever_rounded,
        label: l10n.delete,
        align: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit(product);
          return false;
        }
        return await _confirmDelete(context);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete(product);
        }
      },
      child: row,
    );
  }

  Widget _buildSwipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment align,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
      ),
      alignment: align,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(l10n.confirmDelete),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.no,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.yes,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// 48x48 light-gray tile holding a product icon. Demo shows an emoji, but
/// product records don't carry one — we render the inventory icon in the
/// muted color so the row still gets the visual anchor.
class _EmojiTile extends StatelessWidget {
  final dynamic product;
  const _EmojiTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md + 1),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: context.colors.textSecondary,
        size: 24,
      ),
    );
  }
}

/// Stock label on the right edge of each row. Muted by default, warning
/// yellow for low stock, danger red when fully out.
class _StockLabel extends StatelessWidget {
  final double qty;
  final String unitName;
  final bool isLow;
  final bool isOut;
  final AppLocalizations l10n;

  const _StockLabel({
    required this.qty,
    required this.unitName,
    required this.isLow,
    required this.isOut,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    if (isOut) {
      color = AppColors.danger;
      text = l10n.outOfStockShort;
    } else if (isLow) {
      color = AppColors.warning;
      text = '${l10n.stockShort}: ${NumberFormatter.formatQuantity(qty)}';
    } else {
      color = context.colors.textMuted;
      text = '${l10n.stockShort}: ${NumberFormatter.formatQuantity(qty)}';
    }
    return Text(
      text,
      style: AppTextStyles.caption().copyWith(
        fontSize: 11,
        letterSpacing: 0,
        fontWeight: (isLow || isOut) ? FontWeight.w600 : FontWeight.w400,
        color: color,
      ),
    );
  }
}

/// "Mashhur" chip — brand-light pill with brand-orange text, used on
/// products flagged as popular.
class _PopularChip extends StatelessWidget {
  const _PopularChip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        l10n.popularChip,
        style: AppTextStyles.caption().copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: context.colors.brand,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
