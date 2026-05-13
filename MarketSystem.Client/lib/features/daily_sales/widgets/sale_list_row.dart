import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/data/models/profit_model.dart';

/// Compact one-row sale entry (Variant A timeline). Replaces the old square
/// grid card so 10+ sales/day stay scannable. Tapping opens the detail sheet
/// (handled by the parent screen via `onTap`).
class SaleListRow extends StatelessWidget {
  final DailySalesListItemModel sale;
  final VoidCallback onTap;

  const SaleListRow({super.key, required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(sale.status);
    final customerName = (sale.customerName ?? '').trim();
    final hasCustomer = customerName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _TimeBadge(time: sale.createdAt, isDark: isDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _CustomerAvatar(
                            name: hasCustomer ? customerName : null,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasCustomer ? customerName : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmt(sale.totalAmount)} so\'m',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: sale.status, color: statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4ADE80);
      case 'debt':
        return const Color(0xFFFCD34D);
      case 'closed':
        return const Color(0xFFA5B4FC);
      case 'cancelled':
        return const Color(0xFFFCA5A5);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _fmt(double n) {
    return NumberFormat('#,###', 'en_US').format(n).replaceAll(',', ' ');
  }
}

class _TimeBadge extends StatelessWidget {
  final DateTime time;
  final bool isDark;
  const _TimeBadge({required this.time, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(time),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final String? name;
  final bool isDark;
  const _CustomerAvatar({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initial = (name == null || name!.isEmpty)
        ? '?'
        : name!.trim()[0].toUpperCase();
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (name == null || name!.isEmpty)
            ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.06))
            : const Color(0xFFF28C33).withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: (name == null || name!.isEmpty)
              ? (isDark ? Colors.white54 : Colors.grey)
              : const Color(0xFFF28C33),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
