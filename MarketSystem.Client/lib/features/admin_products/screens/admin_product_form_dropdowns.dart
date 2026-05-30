// Dropdown controls for the Admin Product form.
//
// Extracted from `admin_product_form_screen.dart` as a pure code-move:
// the category + unit dropdowns and their shared `InputDecoration` helper.

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

import '../../../l10n/app_localizations.dart';

class CategoryDropdown extends StatelessWidget {
  final dynamic value;
  final List<dynamic> categories;
  final AppLocalizations l10n;
  final ValueChanged<dynamic> onChanged;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.categories,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<dynamic>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: dropdownDecoration(context, hint: l10n.selectCategory),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            l10n.categoryNotSelected,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
        ...categories.map<DropdownMenuItem<dynamic>>((category) {
          return DropdownMenuItem<dynamic>(
            value: category['id'],
            child: Text(
              category['name'] ?? '',
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

class UnitDropdown extends StatelessWidget {
  final int value;
  final List<Map<String, dynamic>> units;
  final bool enabled;
  final ValueChanged<int?> onChanged;
  const UnitDropdown({
    super.key,
    required this.value,
    required this.units,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: dropdownDecoration(context),
      items: units.map<DropdownMenuItem<int>>((unit) {
        return DropdownMenuItem<int>(
          value: unit['value'] as int,
          child: Row(
            children: [
              Icon(
                unit['icon'] as IconData,
                size: 16,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                unit['name'] as String,
                style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

InputDecoration dropdownDecoration(BuildContext context, {String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium().copyWith(
      color: context.colors.textMuted,
      fontSize: 14,
    ),
    filled: true,
    fillColor: context.colors.inputFill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg + 2,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md + 2),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md + 2),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md + 2),
      borderSide: BorderSide(color: context.colors.brand, width: 1.5),
    ),
  );
}
