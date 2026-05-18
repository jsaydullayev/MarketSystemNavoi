import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtSummaryHeader extends StatelessWidget {
  final String customerName;
  final Map<String, dynamic> debt;
  final String debtStatus;
  final AppLocalizations l10n;

  const DebtSummaryHeader({
    super.key,
    required this.customerName,
    required this.debt,
    required this.debtStatus,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = debtStatus == 'Open';
    final avatarColor = CustomerAvatarPalette.pick(customerName);
    final initial = customerName.isNotEmpty
        ? customerName.characters.first.toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2, AppSpacing.xl, AppSpacing.xl2, AppSpacing.xl2),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: avatarColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.labelLarge().copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  customerName,
                  style: AppTextStyles.titleMedium(),
                ),
              ),
              _StatusBadge(isOpen: isOpen),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: l10n.totalDebt,
                  value:
                      '${NumberFormatter.format(debt['totalDebt'])} ${l10n.currencySom}',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _SummaryChip(
                  label: l10n.remaining,
                  value:
                      '${NumberFormatter.format(debt['remainingDebt'])} ${l10n.currencySom}',
                  color: AppColors.danger,
                  isBold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isOpen ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: AppSpacing.xs + 1),
          Text(
            isOpen ? l10n.open : l10n.cls,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg + 2, vertical: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption().copyWith(fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
