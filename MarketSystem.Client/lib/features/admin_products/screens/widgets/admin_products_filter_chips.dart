import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

import '../../../../l10n/app_localizations.dart';

enum StockFilter { all, low, out }

/// Filter chip row (Hammasi / Kam stok / Tugadi). Demo's `.sales-filter-bar`.
class AdminProductsFilterChips extends StatelessWidget {
  final StockFilter selected;
  final ValueChanged<StockFilter> onChanged;
  final AppLocalizations l10n;

  const AdminProductsFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(String, StockFilter, IconData?)>[
      (l10n.no == 'Yo\'q' ? 'Hammasi' : 'All', StockFilter.all, null),
      ('Kam stok', StockFilter.low, Icons.warning_amber_rounded),
      ('Tugadi', StockFilter.out, Icons.block_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _Chip(
                  label: e.$1,
                  icon: e.$3,
                  active: e.$2 == selected,
                  onTap: () => onChanged(e.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: active ? context.colors.brand : context.colors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? context.colors.brand : context.colors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: active
                    ? context.colors.onBrand
                    : context.colors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active
                    ? context.colors.onBrand
                    : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
