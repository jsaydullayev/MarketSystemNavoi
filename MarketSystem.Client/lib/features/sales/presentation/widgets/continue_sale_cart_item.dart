import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class ContinueSaleCartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isClosed;
  final VoidCallback onEditPrice;
  final VoidCallback onReturn;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  const ContinueSaleCartItem({
    super.key,
    required this.item,
    required this.isClosed,
    required this.onEditPrice,
    required this.onReturn,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final itemTotal = price * qty;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['productName'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${item['quantity']} x ${NumberFormatter.format(item['salePrice'])}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
          Row(
            children: [
              Text(
                NumberFormatter.formatDecimal(itemTotal),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onEditPrice,
                child:
                    const Icon(Icons.edit, size: 14, color: Color(0xFF3B82F6)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isClosed)
                GestureDetector(
                  onTap: onReturn,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.orange.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_return,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Qaytarish',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    _squareButton(Icons.remove, onDecrement),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item['quantity']}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _squareButton(Icons.add, onIncrement),
                  ],
                ),
              if (!isClosed)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 14, color: Color(0xFFEF4444)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF374151)),
      ),
    );
  }
}
