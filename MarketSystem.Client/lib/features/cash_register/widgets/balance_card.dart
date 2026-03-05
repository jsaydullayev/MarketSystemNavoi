import 'package:flutter/material.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.totalBalance,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatAmount(total)} ${l10n.currencySom}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.updatedAt(_formatDate(lastUpdated)),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ],
          if (cashBalance > 0 || clickBalance > 0) ...[
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
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
                  const SizedBox(width: 12),
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

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(0.7))),
                Text(
                  '${amount.toStringAsFixed(0)} ${l10n.currencySom}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
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
