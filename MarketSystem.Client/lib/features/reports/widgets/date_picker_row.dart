import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Date selector strip above the Daily / Ombor report tabs.
///
/// Demo reference: the period control + selected-date row at the top of
/// `id="page-rpt-profit"` — neutral surface card with the brand-tinted
/// calendar icon, the formatted date, prev/next chevrons, and a "tanlash"
/// chip that opens the system picker.
class DatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const DatePickerRow({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.calendar_today_rounded,
                color: context.colors.brand, size: 18),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.date,
                  style: AppTextStyles.bodySmall().copyWith(fontSize: 11),
                ),
                Text(
                  DateFormat('dd MMMM yyyy', 'uz').format(selectedDate),
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            onTap: () =>
                onChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          const SizedBox(width: AppSpacing.xs),
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            onTap: isToday
                ? null
                : () => onChanged(selectedDate.add(const Duration(days: 1))),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: now,
              );
              if (picked != null) onChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg - 2, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.md - 2),
              ),
              child: Text(
                l10n.select,
                style: AppTextStyles.labelSmall().copyWith(
                  fontSize: 12,
                  color: context.colors.brand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? context.colors.brandLight : context.colors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? context.colors.brand : context.colors.textMuted,
        ),
      ),
    );
  }
}
