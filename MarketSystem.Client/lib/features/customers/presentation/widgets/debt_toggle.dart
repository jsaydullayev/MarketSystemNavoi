import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtToggle extends StatelessWidget {
  const DebtToggle({super.key, required this.hasDebt, required this.onChanged});

  final bool hasDebt;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _DebtOption(
          label: l10n.noDebt,
          icon: Icons.check_circle_rounded,
          activeColor: AppColors.success,
          isSelected: !hasDebt,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: AppSpacing.md),
        _DebtOption(
          label: l10n.debtor,
          icon: Icons.money_off_rounded,
          activeColor: AppColors.warning,
          isSelected: hasDebt,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _DebtOption extends StatelessWidget {
  const _DebtOption({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : context.colors.inputFill,
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : context.colors.textMuted,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: isSelected ? activeColor : context.colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
