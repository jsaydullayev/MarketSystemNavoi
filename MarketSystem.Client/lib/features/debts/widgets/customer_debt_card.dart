import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class CustomerDebtCard extends StatelessWidget {
  final String customerName;
  final List<dynamic> customerDebts;
  final double totalDebt;
  final double remainingDebt;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const CustomerDebtCard({
    super.key,
    required this.customerName,
    required this.customerDebts,
    required this.totalDebt,
    required this.remainingDebt,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final hasDebt = remainingDebt > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  customerName: customerName,
                  debtCount: customerDebts.length,
                  hasDebt: hasDebt,
                ),
                const SizedBox(height: AppSpacing.lg),
                _DebtAmountRow(
                  totalDebt: totalDebt,
                  remainingDebt: remainingDebt,
                ),
                if (hasDebt) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _PayButton(onTap: onPay),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtAmountRow extends StatelessWidget {
  final double totalDebt;
  final double remainingDebt;

  const _DebtAmountRow({required this.totalDebt, required this.remainingDebt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg + 2, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AmountItem(
              label: l10n.totalDebt,
              amount: totalDebt,
              color: context.colors.textSecondary,
            ),
          ),
          Container(width: 1, height: 32, color: context.colors.border),
          Expanded(
            child: _AmountItem(
              label: l10n.remaining,
              amount: remainingDebt,
              color: AppColors.danger,
              isBold: true,
              align: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String customerName;
  final int debtCount;
  final bool hasDebt;

  const _CardHeader({
    required this.customerName,
    required this.debtCount,
    required this.hasDebt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = CustomerAvatarPalette.pick(customerName);
    final initial = customerName.isNotEmpty
        ? customerName.characters.first.toUpperCase()
        : '?';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppTextStyles.labelLarge().copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            customerName,
            style: AppTextStyles.labelLarge(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.xs + 1),
          decoration: BoxDecoration(
            color: (hasDebt ? AppColors.danger : AppColors.success)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            l10n.debtCount(debtCount),
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hasDebt ? AppColors.danger : AppColors.success,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final CrossAxisAlignment align;

  const _AmountItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: AppTextStyles.caption().copyWith(fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          '${NumberFormatter.format(amount)} ${l10n.currencySom}',
          style: AppTextStyles.bodyMedium().copyWith(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.payment_rounded, size: 18, color: Colors.white),
        label: Text(
          l10n.pay,
          style: AppTextStyles.bodyMedium().copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2)),
        ),
      ),
    );
  }
}
