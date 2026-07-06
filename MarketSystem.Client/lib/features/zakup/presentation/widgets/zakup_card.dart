import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/auth/permissions.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';

/// One row in the zakup (stock receive) history list.
///
/// Demo reference: the `.receive-item` blocks in `id="page-prod-receive"`
/// (7.3 Stok kiritish) — emoji/icon tile + product name + a row of small
/// chips for quantity and cost price (cost hidden for sellers), with the
/// timestamp and operator on the right.
class ZakupCard extends StatelessWidget {
  final Map<String, dynamic> zakup;

  /// RBAC: zakup.delete ruxsati bo'lganda beriladi. null bo'lsa — swipe orqali
  /// o'chirish ko'rsatilmaydi.
  final VoidCallback? onDelete;

  const ZakupCard({super.key, required this.zakup, this.onDelete});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final createdAt = DateTime.tryParse(zakup['createdAt'] ?? '');

    // Hide cost price unless the user holds data.costPrice
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canViewCostPrice = authProvider.can(Permissions.dataCostPrice);

    final qty = (zakup['quantity'] as num?)?.toDouble() ?? 0.0;
    final qtyStr = qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toString();

    final card = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg + 2,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.lg - 1),
              ),
              child: Icon(
                Icons.shopping_bag_rounded,
                color: context.colors.brand,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.lg + 2),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zakup['productName'] ?? l10n.unknown,
                    style: AppTextStyles.bodyLarge().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _Chip(
                        label: '$qtyStr ${l10n.piece}',
                        icon: Icons.layers_rounded,
                      ),
                      if (canViewCostPrice) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _Chip(
                          label: NumberFormatter.format(
                            zakup['costPrice'] ?? 0,
                          ),
                          icon: Icons.payments_rounded,
                          isAccent: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Date + person
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: AppTextStyles.bodySmall().copyWith(
                      fontSize: 11,
                      color: context.colors.textMuted,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 12,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      zakup['createdBy'] ?? l10n.unknown,
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 11,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onDelete == null) return card;
    return Dismissible(
      key: ValueKey('zakup_${zakup['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md + 2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final ok = await _confirmDelete(context, l10n);
        if (ok) onDelete!();
        return false; // ro'yxat qayta yuklanadi — auto-dismiss shart emas
      },
      child: card,
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(l10n.confirmDelete, style: AppTextStyles.titleMedium()),
            content: Text(
              '"${zakup['productName'] ?? l10n.unknown}" · '
              '${zakup['quantity'] ?? ''} ${l10n.piece}',
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.no),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isAccent;

  const _Chip({required this.label, required this.icon, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    final color = isAccent
        ? context.colors.brand
        : context.colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isAccent ? context.colors.brandLight : context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
