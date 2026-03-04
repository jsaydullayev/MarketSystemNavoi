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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            '${date.day}.${date.month}.${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = createdAt.toString();
      }
    }

    final statusConfig = _statusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusConfig.color.withOpacity(isDark ? 0.2 : 0.15),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header qatori
            Row(
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusConfig.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Savdo #${saleId.length >= 8 ? saleId.substring(0, 8).toUpperCase() : saleId.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusConfig.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusConfig.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // O'chirish
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mijoz va mahsulotlar
            Row(
              children: [
                _InfoChip(
                  icon: Icons.person_outline,
                  label: customerName,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${items.length} ta',
                  isDark: isDark,
                ),
                if (formattedDate.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: formattedDate,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Footer: summa + tugma
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jami summa',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormatter.formatDecimal(totalAmount)} so\'m',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_note_rounded, size: 17),
                  label: const Text('Davom etish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'Debt':
        return _StatusConfig(color: Colors.red, label: 'Qarz');
      case 'Paid':
        return _StatusConfig(color: Colors.green, label: "To'langan");
      default:
        return _StatusConfig(color: Colors.orange, label: 'Draft');
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;
  const _StatusConfig({required this.color, required this.label});
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
