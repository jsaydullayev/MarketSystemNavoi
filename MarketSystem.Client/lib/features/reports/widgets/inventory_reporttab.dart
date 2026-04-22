import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/features/reports/widgets/date_picker_row.dart';
import 'package:market_system_client/features/reports/widgets/empty_report.dart';
import 'package:market_system_client/features/reports/widgets/export_button.dart';
import 'package:market_system_client/features/reports/widgets/inventory_item_card.dart';
import 'package:market_system_client/features/reports/widgets/section_title.dart';
import 'package:market_system_client/features/reports/widgets/stat_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class InventoryReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onExport;
  final bool canViewCostPrice;

  const InventoryReportTab({
    required this.report,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onExport,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DatePickerRow(selectedDate: selectedDate, onChanged: onDateChanged),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.productCount,
                value: '${inventory.length} ${l10n.piece}',
                icon: Icons.inventory_2_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: l10n.incomingPrice,
                value:
                    '${NumberFormatter.formatDecimal(totalCost)} ${l10n.currencySom}',
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.salePrice,
                value:
                    '${NumberFormatter.formatDecimal(totalSaleVal)} ${l10n.currencySom}',
                icon: Icons.sell_outlined,
                color: Colors.green,
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: l10n.potentialProfit,
                  value:
                      '${NumberFormatter.formatDecimal(potentialProfit)} ${l10n.currencySom}',
                  icon: Icons.trending_up_rounded,
                  color: Colors.purple,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionTitle(title: l10n.productList),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${l10n.total}: ${inventory.length} ${l10n.piece}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(
          inventory.length > 50 ? 50 : inventory.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InventoryItemCard(
              item: inventory[i] as Map<String, dynamic>,
              isOwner: isOwner,
              canViewCostPrice: canViewCostPrice,
            ),
          ),
        ),
        if (inventory.length > 50)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                l10n.andMoreProducts(inventory.length - 50),
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ),
        const SizedBox(height: 8),
        ExportButton(onTap: onExport),
      ],
    );
  }
}
