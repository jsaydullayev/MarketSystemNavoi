// lib/features/zakup/presentation/widgets/zakup_card.dart

import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ZakupCard extends StatelessWidget {
  final Map<String, dynamic> zakup;

  const ZakupCard({super.key, required this.zakup});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createdAt = DateTime.tryParse(zakup['createdAt'] ?? '');

    final qty = (zakup['quantity'] as num?)?.toDouble() ?? 0.0;
    final qtyStr =
        qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.shopping_bag_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zakup['productName'] ?? l10n.unknown,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _Chip(
                        label: '$qtyStr ${l10n.piece}',
                        icon: Icons.layers_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _Chip(
                        label: NumberFormatter.format(zakup['costPrice'] ?? 0),
                        icon: Icons.payments_rounded,
                        isDark: isDark,
                        isAccent: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date + person
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      zakup['createdBy'] ?? l10n.unknown,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isAccent;

  const _Chip({
    required this.label,
    required this.icon,
    required this.isDark,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAccent
        ? AppColors.primary
        : (isDark ? Colors.white54 : Colors.grey.shade600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAccent
            ? AppColors.primary.withOpacity(0.08)
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
