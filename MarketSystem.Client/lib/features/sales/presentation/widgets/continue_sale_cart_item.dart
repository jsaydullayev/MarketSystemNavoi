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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final itemTotal = price * qty;

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mahsulot nomi + O'chirish
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['productName'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isClosed)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Color(0xFFEF4444)),
                  ),
              ],
            ),
            const SizedBox(height: 2),

            // Miqdor x narx
            Text(
              '${qty % 1 == 0 ? qty.toInt() : qty} × ${NumberFormatter.format(price)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),

            // Jami + Tahrirlash
            Row(
              children: [
                Expanded(
                  child: Text(
                    NumberFormatter.formatDecimal(itemTotal),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isClosed)
                  GestureDetector(
                    onTap: onEditPrice,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 11, color: Color(0xFF3B82F6)),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // Qaytarish yoki miqdor o'zgartirish
            if (isClosed)
              GestureDetector(
                onTap: onReturn,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_return_rounded,
                          size: 12, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Qaytarish',
                        style: TextStyle(
                          fontSize: 10,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QtyButton(icon: Icons.remove_rounded, onTap: onDecrement),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      qty % 1 == 0 ? '${qty.toInt()}' : '$qty',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  _QtyButton(icon: Icons.add_rounded, onTap: onIncrement),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: const Color(0xFF3B82F6)),
      ),
    );
  }
}
