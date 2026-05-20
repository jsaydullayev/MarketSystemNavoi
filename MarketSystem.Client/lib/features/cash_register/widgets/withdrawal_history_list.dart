import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Withdrawal history list — a stack of cards each showing a single
/// withdrawal: red icon tile, amount, optional comment, date, and user.
///
/// Demo reference: list-row styling consistent with the receive/log lists
/// elsewhere in the design (white surface, soft border, neutral chrome).
class WithdrawalHistoryList extends StatelessWidget {
  final List withdrawals;
  final AppLocalizations l10n;

  const WithdrawalHistoryList({
    super.key,
    required this.withdrawals,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl4),
        decoration: BoxDecoration(
          color: context.colors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.noWithdrawals,
              style: AppTextStyles.bodyLarge().copyWith(
                color: context.colors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: withdrawals.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md + 2),
      itemBuilder: (context, index) {
        final w = withdrawals[index];
        return _WithdrawalItem(withdrawal: w, l10n: l10n);
      },
    );
  }
}

class _WithdrawalItem extends StatelessWidget {
  final dynamic withdrawal;
  final AppLocalizations l10n;

  const _WithdrawalItem({required this.withdrawal, required this.l10n});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(AppRadius.lg - 2),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.lg + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormatter.format(withdrawal.amount)} ${l10n.currencySom}',
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    fontSize: 15,
                  ),
                ),
                if (withdrawal.comment != null &&
                    withdrawal.comment.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    withdrawal.comment,
                    style: AppTextStyles.bodySmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDate(withdrawal.withdrawalDate),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (withdrawal.userName != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.md - 2),
              ),
              child: Text(
                withdrawal.userName!,
                style: AppTextStyles.bodySmall().copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
