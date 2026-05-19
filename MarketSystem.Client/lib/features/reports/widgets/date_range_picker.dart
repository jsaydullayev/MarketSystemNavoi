import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// "Boshlanish — Tugash" picker shown above the Monthly report tab.
///
/// Demo reference: same neutral surface card pattern as `DatePickerRow`,
/// but with a date-range icon, "Boshi"/"Oxiri" chips, and a calendar
/// edit-icon hint on the right.
class DateRangeRow extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onChanged;

  const DateRangeRow({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          initialDateRange: DateTimeRange(start: startDate, end: endDate),
        );
        if (picked != null) {
          onChanged(
            DateTime(picked.start.year, picked.start.month, picked.start.day),
            DateTime(picked.end.year, picked.end.month, picked.end.day),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.date_range_rounded,
                  color: AppColors.brand, size: 18),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Row(
                children: [
                  _DateChip(label: l10n.from, date: startDate),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg - 2),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                  _DateChip(label: l10n.to, date: endDate),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;

  const _DateChip({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(fontSize: 10),
        ),
        Text(
          DateFormat('dd.MM.yyyy').format(date),
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
