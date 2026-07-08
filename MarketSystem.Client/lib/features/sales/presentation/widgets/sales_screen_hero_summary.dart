import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sale_entity.dart';

/// Orange gradient hero card — matches demo's "BUGUN JAMI" tile.
class SalesHeroSummary extends StatelessWidget {
  final List<SaleEntity> sales;
  final AppLocalizations l10n;

  const SalesHeroSummary({super.key, required this.sales, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Single pass over `sales`: previously `todaySales` was a lazy .where(), so
    // fold + length + where(debt) + where(draft) each RE-RAN the date predicate
    // over the whole list (~4 passes) on every rebuild (incl. each chip tap).
    final today = DateTime.now();
    double totalToday = 0;
    int countToday = 0;
    int debtCount = 0;
    int ongoing = 0;
    for (final s in sales) {
      if (s.createdAt.year != today.year ||
          s.createdAt.month != today.month ||
          s.createdAt.day != today.day) {
        continue;
      }
      totalToday += s.totalAmount;
      countToday++;
      final status = s.getStatusText().toLowerCase();
      if (status == 'debt') {
        debtCount++;
      } else if (status == 'draft') {
        ongoing++;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.brand, context.colors.brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: context.colors.brand.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BUGUN JAMI',
                  style: AppTextStyles.caption().copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(today),
                  style: AppTextStyles.labelSmall().copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${NumberFormatter.format(totalToday)} UZS',
                style: AppTextStyles.displayMedium().copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _heroStat('$countToday', 'chek'),
                _heroDivider(),
                _heroStat('$ongoing', l10n.ongoing.toLowerCase()),
                _heroDivider(),
                _heroStat('$debtCount', l10n.debt.toLowerCase()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withValues(alpha: 0.25),
  );
}
