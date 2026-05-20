import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/reports/widgets/date_picker_row.dart';
import 'package:market_system_client/features/reports/widgets/empty_report.dart';
import 'package:market_system_client/features/reports/widgets/inventory_item_card.dart';
import 'package:market_system_client/features/reports/widgets/section_title.dart';
import 'package:market_system_client/features/reports/widgets/stat_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Ombor (warehouse) tab inside the Reports screen.
///
/// Layout: date selector, 2x2 KPI grid (count, incoming, sale value,
/// potential profit), then the per-product inventory list capped at 50
/// rows with an "and more" footer when the warehouse is larger.
class InventoryReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool canViewCostPrice;

  const InventoryReportTab({
    super.key,
    required this.report,
    required this.selectedDate,
    required this.onDateChanged,
    this.canViewCostPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (report == null) return const EmptyReport();

    final inventory = report!['inventoryReport'] is List
        ? report!['inventoryReport'] as List
        : [];
    final totalCost =
        (report!['totalInventoryCost'] as num?)?.toDouble() ?? 0.0;
    final totalSaleVal =
        (report!['totalInventorySaleValue'] as num?)?.toDouble() ?? 0.0;
    final potentialProfit = totalSaleVal - totalCost;

    final isOwner = inventory.isNotEmpty &&
        inventory.first is Map<String, dynamic> &&
        (inventory.first as Map<String, dynamic>)['potentialProfit'] != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl4),
      children: [
        DatePickerRow(selectedDate: selectedDate, onChanged: onDateChanged),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.productCount,
                value: '${inventory.length} ${l10n.piece}',
                icon: Icons.inventory_2_outlined,
                color: context.colors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: StatCard(
                title: l10n.incomingPrice,
                value:
                    '${NumberFormatter.formatDecimal(totalCost)} ${l10n.currencySom}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.salePrice,
                value:
                    '${NumberFormatter.formatDecimal(totalSaleVal)} ${l10n.currencySom}',
                icon: Icons.sell_outlined,
                color: AppColors.success,
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: StatCard(
                  title: l10n.potentialProfit,
                  value:
                      '${NumberFormatter.formatDecimal(potentialProfit)} ${l10n.currencySom}',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionTitle(title: l10n.productList),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.md - 2),
              ),
              child: Text(
                '${l10n.total}: ${inventory.length} ${l10n.piece}',
                style: AppTextStyles.labelSmall().copyWith(
                  fontSize: 12,
                  color: context.colors.brand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md + 2),
        ...List.generate(
          inventory.length > 50 ? 50 : inventory.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InventoryItemCard(
              item: inventory[i] as Map<String, dynamic>,
              isOwner: isOwner,
              canViewCostPrice: canViewCostPrice,
            ),
          ),
        ),
        if (inventory.length > 50)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: Text(
                l10n.andMoreProducts(inventory.length - 50),
                style: AppTextStyles.bodySmall().copyWith(fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}
