import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/profit_model.dart';

/// Filter shown beneath the hero. `all` means no filter — show every sale.
enum DailySaleFilter { all, paid, debt }

/// Variant C hero: big "Sof foyda" callout (Owner only) + 3 mini stats
/// (Jami / To'langan / Qarz). Foyda is intentionally NOT duplicated in the
/// mini row — it already lives in the hero. Sellers don't see profit at all,
/// so the hero collapses to just the mini stats for them.
///
/// The three mini stats double as the filter toggle: tap "Jami" to clear,
/// tap "To'langan" / "Qarz" to drill down to that status.
class DailySummaryCard extends StatelessWidget {
  final DailySalesListModel data;
  final DailySaleFilter selectedFilter;
  final ValueChanged<DailySaleFilter> onFilterChanged;

  const DailySummaryCard({
    super.key,
    required this.data,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isOwner = auth.user?['role'] == 'Owner';
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (isOwner) _buildProfitHero(context, l10n),
        if (isOwner) const SizedBox(height: AppSpacing.lg),
        _buildMiniStatsRow(context, l10n),
      ],
    );
  }

  Widget _buildProfitHero(BuildContext context, AppLocalizations l10n) {
    final profit = data.summaryProfit ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl2, horizontal: AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.brand, context.colors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: context.colors.brand.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.netProfit.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              '${profit >= 0 ? '+' : ''}${_fmt(profit)} ${l10n.currencySom}',
              style: AppTextStyles.displayLarge().copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMMM, yyyy').format(data.date),
            style: AppTextStyles.bodySmall()
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatsRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: l10n.totalSale,
            value: data.totalSales,
            color: context.colors.text,
            isSelected: selectedFilter == DailySaleFilter.all,
            onTap: () => onFilterChanged(DailySaleFilter.all),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MiniStat(
            label: l10n.paid,
            value: data.totalPaidSales,
            color: AppColors.success,
            isSelected: selectedFilter == DailySaleFilter.paid,
            onTap: () => onFilterChanged(DailySaleFilter.paid),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MiniStat(
            label: l10n.debt,
            value: data.totalDebtSales,
            color: AppColors.warning,
            isSelected: selectedFilter == DailySaleFilter.debt,
            onTap: () => onFilterChanged(DailySaleFilter.debt),
          ),
        ),
      ],
    );
  }

  static String _fmt(double n) {
    final abs = n.abs();
    if (abs >= 1000) {
      return NumberFormat('#,###', 'en_US').format(n).replaceAll(',', ' ');
    }
    return n.toStringAsFixed(0);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : context.colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.caption().copyWith(
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  _short(value),
                  style: AppTextStyles.titleMedium().copyWith(
                    fontSize: 16,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _short(double n) {
    if (n.abs() >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n.abs() >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)}K';
    }
    return n.toStringAsFixed(0);
  }
}
