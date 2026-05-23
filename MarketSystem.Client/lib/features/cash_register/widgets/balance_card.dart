import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Orange gradient "hero" balance card.
///
/// Demo reference: the `.z-header` block in `id="page-staff-shift"` (10.4
/// Smena yopish / Z-report). Brand-orange gradient block at the top of the
/// cash register screen with a large total, a meta line for last update,
/// and optional cash/click chips on a translucent divider.
class BalanceCard extends StatelessWidget {
  final double cashBalance;
  final double clickBalance;
  final DateTime? lastUpdated;

  const BalanceCard({
    super.key,
    required this.cashBalance,
    required this.clickBalance,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final total = cashBalance + clickBalance;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.brand, context.colors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: context.colors.brand.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Text(
                l10n.totalBalance.toUpperCase(),
                style: AppTextStyles.labelSmall().copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${NumberFormatter.format(total)} ${l10n.currencySom}',
            style: AppTextStyles.displayLarge().copyWith(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.updatedAt(_formatDate(lastUpdated)),
              style: AppTextStyles.bodySmall().copyWith(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 12,
              ),
            ),
          ],
          if (cashBalance > 0 || clickBalance > 0) ...[
            const SizedBox(height: AppSpacing.xl2),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.20),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (cashBalance > 0)
                  Expanded(
                    child: _BalanceChip(
                      icon: Icons.payments_outlined,
                      label: l10n.cash,
                      amount: cashBalance,
                    ),
                  ),
                if (cashBalance > 0 && clickBalance > 0)
                  const SizedBox(width: AppSpacing.lg),
                if (clickBalance > 0)
                  Expanded(
                    child: _BalanceChip(
                      icon: Icons.phone_android_outlined,
                      label: l10n.click,
                      amount: clickBalance,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _BalanceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;

  const _BalanceChip({
    required this.icon,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg + 2,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                Text(
                  '${NumberFormatter.format(amount)} ${l10n.currencySom}',
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
