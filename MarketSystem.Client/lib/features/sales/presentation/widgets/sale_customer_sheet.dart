import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'quick_add_customer_sheet.dart';

/// Customer-selection bottom sheet.
///
/// [selectedId] highlights the currently selected customer.
/// [onSelected] is called with the tapped customer map; close the sheet
/// and update parent state inside the callback.
void showCustomerSelectionSheet(
  BuildContext context, {
  required List<dynamic> customers,
  required String? selectedId,
  required void Function(Map<String, dynamic> customer) onSelected,
}) {
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Row(
              children: [
                Text(
                  l10n.selectCustomerTitle,
                  style: AppTextStyles.titleMedium(),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close, color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          // Yangi mijoz qo'shish — quick-add oynasini ochadi; yaratilsa, o'sha
          // mijozni shu yerda tanlaydi (parent ro'yxatga ham qo'shadi). Ro'yxat
          // bo'sh bo'lsa ham ko'rinib turadi, shuning uchun ustki qismда.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: InkWell(
              onTap: () async {
                final navigator = Navigator.of(ctx);
                final created = await showQuickAddCustomerSheet(context);
                if (created != null) {
                  navigator.pop();
                  onSelected(created);
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.colors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.colors.brand, width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colors.brand,
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Text(
                        l10n.addNewCustomer,
                        style: AppTextStyles.labelLarge().copyWith(
                          color: context.colors.brandDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.add_rounded, color: context.colors.brand),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Text(
                      l10n.noCustomersFound,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, index) {
                      final customer = customers[index] as Map<String, dynamic>;
                      final name = customer['fullName'] ?? l10n.unknown;
                      final phone = customer['phone'] ?? '';
                      final isSelected =
                          selectedId == customer['id']?.toString();

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelected(customer);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.brandLight
                                : context.colors.inputFill,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isSelected
                                  ? context.colors.brand
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected
                                    ? context.colors.brand
                                    : context.colors.textMuted,
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.toString(),
                                      style: AppTextStyles.labelLarge(),
                                    ),
                                    if (phone.isNotEmpty)
                                      Text(
                                        phone.toString(),
                                        style: AppTextStyles.bodySmall()
                                            .copyWith(
                                              color:
                                                  context.colors.textSecondary,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: context.colors.brand,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.xl2),
        ],
      ),
    ),
  );
}
