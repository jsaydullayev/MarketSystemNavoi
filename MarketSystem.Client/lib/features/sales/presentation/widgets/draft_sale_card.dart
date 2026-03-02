import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class DraftSaleCard extends StatelessWidget {
  final dynamic sale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DraftSaleCard({
    super.key,
    required this.sale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final saleId = sale['id']?.toString() ?? '';
    final customerName = sale['customerName'] ?? 'Mijozsiz';
    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = sale['status'] ?? '';
    final items = sale['items'] as List<dynamic>? ?? [];
    final createdAt = sale['createdAt'];

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt.toString();
      }
    }

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'Debt':
        statusColor = Colors.red;
        statusLabel = 'Qarz';
        break;
      case 'Paid':
        statusColor = Colors.green;
        statusLabel = 'To\'langan';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Draft';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID + Status + Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savdo #${saleId.length >= 8 ? saleId.substring(0, 8) : saleId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline,
                        size: 20, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mijoz
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                customerName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Mahsulotlar soni
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                '${items.length} ta mahsulot',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Sana
          if (formattedDate.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Footer: Summa + Davom etish
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormatter.formatDecimal(totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Davom etish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
