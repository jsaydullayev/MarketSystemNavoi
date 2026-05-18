// Compact debtor row used by the sales-debtors quick views. Mirrors the
// "8.1 Mijozlar ro'yxati" pattern from the HTML demo: coloured avatar, name +
// phone, debt badge, and two side-by-side action buttons (history + pay).
//
// Public constructor (debtor, onPaymentTap, onHistoryTap) is kept identical so
// other screens that already import this widget continue to compile.

import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtorCard extends StatelessWidget {
  final dynamic debtor;
  final VoidCallback onPaymentTap;
  final VoidCallback onHistoryTap;

  const DebtorCard({
    super.key,
    required this.debtor,
    required this.onPaymentTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customerName =
        (debtor['customerName'] as String?) ?? l10n.noCustomer;
    final customerPhone = debtor['customerPhone'] as String?;
    final remainingDebt =
        (debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;

    final initial = customerName.isNotEmpty
        ? customerName.characters.first.toUpperCase()
        : '?';
    final avatarColor = CustomerAvatarPalette.pick(customerName);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            // Avatar — solid colour from CustomerAvatarPalette so the same
            // customer keeps the same colour across all "qarzdorlar" views.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTextStyles.labelLarge().copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customerName,
                    style: AppTextStyles.labelLarge(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customerPhone != null && customerPhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      customerPhone,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md + 2,
                      vertical: AppSpacing.xs + 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(AppRadius.md - 2),
                    ),
                    child: Text(
                      '${NumberFormatter.formatDecimal(remainingDebt)} ${l10n.currencySom}',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Column(
              children: [
                _ActionButton(
                  icon: Icons.history_rounded,
                  onTap: onHistoryTap,
                  background: AppColors.inputFill,
                  iconColor: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionButton(
                  icon: Icons.payments_outlined,
                  onTap: onPaymentTap,
                  background: AppColors.brandLight,
                  iconColor: AppColors.brand,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
