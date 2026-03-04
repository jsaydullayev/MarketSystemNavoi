import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class InventoryItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isOwner;

  const InventoryItemCard({required this.item, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = item['productName'] as String? ?? l10n.unknown;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final costPrice = (item['costPrice'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (item['totalCostValue'] as num?)?.toDouble() ?? 0.0;
    final totalSale = (item['totalSaleValue'] as num?)?.toDouble() ?? 0.0;
    final potentialProfit = isOwner && item['potentialProfit'] != null
        ? (item['potentialProfit'] as num).toDouble()
        : null;

    final stockColor = qty > 10
        ? Colors.green
        : qty > 0
            ? Colors.orange
            : Colors.red;

    final qtyStr = qty % 1 == 0
        ? '${qty.toInt()} ${l10n.piece}'
        : '${qty.toStringAsFixed(1)} ${l10n.piece}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: stockColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      qtyStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: l10n.purchasePrice,
                  value:
                      '${NumberFormatter.formatDecimal(costPrice)} ${l10n.currencySom}',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: l10n.sellingPrice,
                  value:
                      '${NumberFormatter.formatDecimal(salePrice)} ${l10n.currencySom}',
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: l10n.totalCost,
                  value:
                      '${NumberFormatter.formatDecimal(totalCost)} ${l10n.currencySom}',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: l10n.totalValue,
                  value:
                      '${NumberFormatter.formatDecimal(totalSale)} ${l10n.currencySom}',
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          if (isOwner && potentialProfit != null && potentialProfit != 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: potentialProfit > 0
                    ? Colors.green.withOpacity(0.08)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    potentialProfit > 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: potentialProfit > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.potentialProfit}: ${NumberFormatter.formatDecimal(potentialProfit)} ${l10n.currencySom}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: potentialProfit > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _InfoTile({
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
