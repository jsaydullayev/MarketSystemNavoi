import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class PaymentTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PaymentTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final types = <Map<String, dynamic>>[
      {'value': 'Cash', 'label': l10n.cash, 'icon': Icons.payments_rounded},
      {'value': 'Terminal', 'label': l10n.card, 'icon': Icons.credit_card_rounded},
      {'value': 'Transfer', 'label': 'Transfer', 'icon': Icons.swap_horiz_rounded},
    ];

    return Row(
      children: [
        for (var i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _PaymentTypeOption(
              value: types[i]['value'] as String,
              label: types[i]['label'] as String,
              icon: types[i]['icon'] as IconData,
              isSelected: selected == types[i]['value'],
              onTap: () => onChanged(types[i]['value'] as String),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentTypeOption extends StatelessWidget {
  const _PaymentTypeOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg + 2),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.brand : context.colors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          border: Border.all(
            color: isSelected ? context.colors.brand : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : context.colors.brand,
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.colors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
