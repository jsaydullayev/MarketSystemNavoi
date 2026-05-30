// Owner-detail stats grid: Mahsulotlar / Sotuvlar / Mijozlar / Qarz tiles.
// Extracted verbatim from owner_detail_screen.dart (pure code-move).

import 'package:flutter/material.dart';

import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models/owner_detail.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.stats});
  final OwnerDetailStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (ctx, c) {
        final cross = c.maxWidth < 600 ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: cross == 2 ? 1.7 : 1.35,
          children: [
            _StatTile(
              label: l10n.statProducts.toUpperCase(),
              value: _fmtNum(stats.productsCount),
              subtitle: l10n.statActiveTypes,
              color: context.colors.text,
              icon: Icons.inventory_2_outlined,
            ),
            _StatTile(
              label: l10n.statSales.toUpperCase(),
              value: _fmtNum(stats.salesCount),
              subtitle: l10n.statTotalReceipts,
              color: AppColors.success,
              icon: Icons.point_of_sale_outlined,
            ),
            _StatTile(
              label: l10n.statCustomers.toUpperCase(),
              value: _fmtNum(stats.customersCount),
              subtitle: l10n.statActiveCustomers,
              color: context.colors.text,
              icon: Icons.people_outline,
            ),
            _StatTile(
              label: l10n.debt.toUpperCase(),
              value: _fmtMoney(stats.outstandingDebt),
              subtitle: l10n.statTotalUZS,
              color: stats.outstandingDebt > 0
                  ? AppColors.warning
                  : context.colors.text,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        );
      },
    );
  }

  String _fmtNum(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  String _fmtMoney(double d) {
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)}K';
    return d.toStringAsFixed(0);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Row(
            children: [
              Icon(icon, size: 14, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
