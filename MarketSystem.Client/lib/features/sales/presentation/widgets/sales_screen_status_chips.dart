import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sale_entity.dart';
import 'sales_screen_status_helpers.dart';

class SalesStatusChips extends StatelessWidget {
  final List<SaleEntity> sales;
  final AppLocalizations l10n;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  const SalesStatusChips({
    super.key,
    required this.sales,
    required this.l10n,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> statuses = [
      {'id': 'all', 'label': l10n.all},
      // Status is still 'Draft' on the backend; only the user-facing
      // label changes — "Davom etayotgan" / "В процессе" reads more
      // accurately for a sale the seller is mid-way through.
      {'id': 'draft', 'label': l10n.ongoing},
      {'id': 'paid', 'label': l10n.paid},
      {'id': 'closed', 'label': l10n.closed},
      {'id': 'debt', 'label': l10n.debt},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final s = statuses[index];
          final id = s['id'] as String;
          final bool isSelected = selectedStatus == id;
          final int count = id == 'all'
              ? sales.length
              : sales
                    .where((item) => item.getStatusText().toLowerCase() == id)
                    .length;
          // Each status carries a logical colour (see getStatusColor); the
          // "all" chip stays a neutral grey. Chips wear the colour as a soft
          // tint — the selected one deepens the fill and gains a ring.
          final Color color = id == 'all'
              ? context.colors.textSecondary
              : SalesStatusHelpers.getStatusColor(context, id);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: () => onStatusSelected(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s['label'] as String,
                      style: AppTextStyles.labelSmall().copyWith(
                        color: color,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        letterSpacing: 0,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: isSelected ? 0.30 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.caption().copyWith(
                          color: color,
                          fontSize: 10,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
