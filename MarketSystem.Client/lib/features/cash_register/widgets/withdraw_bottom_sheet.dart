import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Modal bottom sheet for withdrawing cash or Click funds.
///
/// Demo reference: form blocks (`.form-block`) + brand-tinted segmented
/// picker for selecting which balance to withdraw from. Uses `AppTextInput`
/// for the amount/comment fields, `AppDangerButton` for the destructive
/// confirm, and `AppSecondaryButton` for cancel.
class WithdrawBottomSheet extends StatefulWidget {
  final TextEditingController amountController;
  final TextEditingController commentController;
  final double cashBalance;
  final double clickBalance;
  final bool isWithdrawing;
  final void Function(String type) onConfirm;

  const WithdrawBottomSheet({
    super.key,
    required this.amountController,
    required this.commentController,
    required this.cashBalance,
    required this.clickBalance,
    required this.isWithdrawing,
    required this.onConfirm,
  });

  @override
  State<WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<WithdrawBottomSheet> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl2)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl3,
        0,
        AppSpacing.xl3,
        AppSpacing.xl3 + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xl2,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                ),
                child: const Icon(
                  Icons.arrow_circle_up_outlined,
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.withdrawCash,
                      style: AppTextStyles.titleMedium(),
                    ),
                    Text(
                      'Pul turini va miqdorini tanlang',
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl3),
          Text(
            'PUL TURI',
            style: AppTextStyles.caption().copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Row(
            children: [
              _TypeChip(
                label: l10n.cash,
                icon: Icons.payments_outlined,
                value: 'cash',
                balance: widget.cashBalance,
                selected: _selectedType == 'cash',
                onTap: () => setState(() => _selectedType = 'cash'),
              ),
              const SizedBox(width: AppSpacing.lg),
              _TypeChip(
                label: l10n.click,
                icon: Icons.phone_android_outlined,
                value: 'click',
                balance: widget.clickBalance,
                selected: _selectedType == 'click',
                onTap: () => setState(() => _selectedType = 'click'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl2),
          AppTextInput(
            label: l10n.amount,
            hint: '0',
            controller: widget.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.monetization_on_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextInput(
            label: l10n.comment,
            controller: widget.commentController,
            prefixIcon: Icons.comment_outlined,
          ),
          const SizedBox(height: AppSpacing.xl3),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: AppDangerButton(
                  label: l10n.confirm,
                  isLoading: widget.isWithdrawing,
                  onPressed: (_selectedType == null || widget.isWithdrawing)
                      ? null
                      : () => widget.onConfirm(_selectedType!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final double balance;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md + 2,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: selected ? context.colors.brandLight : context.colors.inputFill,
            borderRadius: BorderRadius.circular(AppRadius.lg - 2),
            border: Border.all(
              color: selected ? context.colors.brand : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? context.colors.brand : context.colors.textMuted,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.bodyMedium().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? context.colors.brand : context.colors.textSecondary,
                ),
              ),
              Text(
                '${NumberFormatter.format(balance)} ${l10n.currencySom}',
                style: AppTextStyles.bodySmall().copyWith(
                  fontSize: 11,
                  color: context.colors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
