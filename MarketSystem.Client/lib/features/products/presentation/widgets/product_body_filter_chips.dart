// Products body — category / stock filter chips.
//
// Horizontal-scroll filter chips row, the chip data model, and the individual
// chip widget. Extracted from `product_body.dart` as part of a code-move
// refactor.

import 'package:flutter/material.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Reserved synthetic filter values. `null` = "Hammasi" selected; these two
/// values are the low-stock / out-of-stock pseudo-categories; any other value
/// is a real category name.
const String kProductFilterLow = '__low__';
const String kProductFilterOut = '__out__';

/// Horizontal-scroll filter chips row. First chip is "Hammasi" (selected
/// by default) and uses inverted colors when selected; the rest use the
/// light gray pill. Matches demo's `.sales-filter-bar`.
class ProductFilterChipsRow extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final AppLocalizations l10n;

  const ProductFilterChipsRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <_FilterChipData>[
      _FilterChipData(
        label: l10n.all,
        value: null,
        color: context.colors.textSecondary,
      ),
      _FilterChipData(
        label: l10n.filterLowStock,
        value: kProductFilterLow,
        leadingIcon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      _FilterChipData(
        label: l10n.filterOutOfStock,
        value: kProductFilterOut,
        leadingIcon: Icons.block_rounded,
        color: AppColors.danger,
      ),
      ...categories.map(
        (c) => _FilterChipData(label: c, value: c, color: context.colors.brand),
      ),
    ];

    return SizedBox(
      height: 34,
      child: ScrollConfiguration(
        // Hide the desktop scrollbar — the chips already imply horizontal scroll
        // through their overflow and visible scrollbars look out of place.
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => 8.width,
          itemBuilder: (context, i) {
            final chip = chips[i];
            final isSelected = selected == chip.value;
            return _FilterChip(
              label: chip.label,
              leadingIcon: chip.leadingIcon,
              color: chip.color,
              isSelected: isSelected,
              onTap: () => onSelected(isSelected ? null : chip.value),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final String? value;
  final IconData? leadingIcon;

  /// Logical chip colour — amber for low-stock, red for out-of-stock,
  /// brand for category chips, neutral grey for "Hammasi".
  final Color color;
  const _FilterChipData({
    required this.label,
    required this.value,
    required this.color,
    this.leadingIcon,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        // The chip wears its logical colour as a soft tint; the selected
        // one deepens the fill and gains a matching ring.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg + 2,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: color),
                4.width,
              ],
              Text(
                label,
                style: AppTextStyles.labelSmall().copyWith(
                  fontSize: 12,
                  letterSpacing: 0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
