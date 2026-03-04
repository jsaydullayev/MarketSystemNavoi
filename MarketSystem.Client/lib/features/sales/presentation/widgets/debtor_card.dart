import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class DebtorCard extends StatelessWidget {
  final dynamic debtor;
  final VoidCallback onPaymentTap;
  final VoidCallback onHistoryTap;

  const DebtorCard({
    super.key,
    required this.debtor,
    required this.onPaymentTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerName = debtor['customerName'] ?? 'Mijozsiz';
    final customerPhone = debtor['customerPhone'];
    final remainingDebt = (debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;

    // Avatar harf
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.red.withOpacity(0.2)
              : Colors.red.withOpacity(0.15),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.red.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customerPhone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      customerPhone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Qarz badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${NumberFormatter.formatDecimal(remainingDebt)} so\'m',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Tugmalar
            Column(
              children: [
                _ActionButton(
                  icon: Icons.history_rounded,
                  color: Colors.blue,
                  onTap: onHistoryTap,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.payments_outlined,
                  color: Colors.green,
                  onTap: onPaymentTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
