import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtToggle extends StatelessWidget {
  const DebtToggle({
    super.key,
    required this.hasDebt,
    required this.onChanged,
  });

  final bool hasDebt;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _DebtOption(
          label: l10n.noDebt,
          icon: Icons.check_circle_rounded,
          activeColor: Colors.green,
          isSelected: !hasDebt,
          isDark: isDark,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 10),
        _DebtOption(
          label: l10n.debtor,
          icon: Icons.money_off_rounded,
          activeColor: Colors.orange,
          isSelected: hasDebt,
          isDark: isDark,
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
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.15)
                : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? activeColor : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
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
