import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  const DebtCard({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final totalDebt = (debt['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (debt['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final status = debt['status']?.toString() ?? 'Open';
    final createdAt = debt['createdAt'];
    final saleItems = debt['saleItems'] as List<dynamic>?;
    final l10n = AppLocalizations.of(context)!;

    final formattedDate =
        NumberFormatter.formatDateTime(createdAt, showTime: true);

    final isOpen = status.toLowerCase() == 'open';
    final hasProducts = saleItems != null && saleItems.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOpen ? Colors.red.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isOpen
              ? LinearGradient(
                  colors: [Colors.red.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          isOpen ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOpen ? Colors.red : Colors.green,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOpen ? Icons.money_off : Icons.check_circle,
                          size: 14,
                          color: isOpen ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen ? l10n.inDebt : l10n.completed,
                          style: TextStyle(
                            color: isOpen ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _BuildAmountColumn(
                      label: l10n.totalSum,
                      amount: totalDebt,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BuildAmountColumn(
                      label: l10n.remainingDebt,
                      amount: remainingDebt,
                      color: isOpen ? Colors.red : Colors.green,
                      isMain: true,
                    ),
                  ),
                ],
              ),

              // Show products if available
              if (hasProducts) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Products header with time
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${l10n.products} (${saleItems.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormatter.formatTime(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...saleItems.map((item) => _BuildSaleItem(item: item)),
              ] else if (!hasProducts && isOpen) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.noProductsFound,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildSaleItem extends StatelessWidget {
  final dynamic item;
  const _BuildSaleItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productName = item['productName']?.toString() ?? l10n.unknownProduct;
    final quantity = item['quantity'] as num? ?? 0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final comment = item['comment']?.toString();

    final quantityDisplay = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 16,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '$quantityDisplay ${l10n.piece}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '× ${NumberFormatter.format(salePrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.format(totalPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                l10n.currencySom,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildAmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isMain;
  const _BuildAmountColumn(
      {required this.label,
      required this.amount,
      required this.color,
      this.isMain = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormatter.format(amount),
          style: TextStyle(
            fontSize: isMain ? 18 : 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
