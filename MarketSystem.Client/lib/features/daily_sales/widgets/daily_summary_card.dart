import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (isOwner) _buildProfitHero(context, isDark, l10n),
        if (isOwner) const SizedBox(height: 12),
        _buildMiniStatsRow(context, isDark, l10n),
      ],
    );
  }

  Widget _buildProfitHero(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    final profit = data.summaryProfit ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1843B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1843B8).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.netProfit.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              '${profit >= 0 ? '+' : ''}${_fmt(profit)} ${l10n.currencySom}',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: profit >= 0 ? const Color(0xFF4ADE80) : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMMM, yyyy').format(data.date),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatsRow(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: l10n.totalSale,
            value: data.totalSales,
            color: isDark ? Colors.white : Colors.black87,
            isSelected: selectedFilter == DailySaleFilter.all,
            onTap: () => onFilterChanged(DailySaleFilter.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: l10n.paid,
            value: data.totalPaidSales,
            color: const Color(0xFF4ADE80),
            isSelected: selectedFilter == DailySaleFilter.paid,
            onTap: () => onFilterChanged(DailySaleFilter.paid),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: l10n.debt,
            value: data.totalDebtSales,
            color: const Color(0xFFFCD34D),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : (isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.06)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.4,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  _short(value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
