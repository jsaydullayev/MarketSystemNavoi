import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ZakupCard extends StatelessWidget {
  final Map<String, dynamic> zakup;

  const ZakupCard({super.key, required this.zakup});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(20), // Yumshoq burchaklar
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icon qismi (Sening binafsharang koding o'rniga Primary Blue)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.12), // Nafis och ko'k
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: AppTheme.primaryDark,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zakup['productName'] ?? l10n.unknown,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Miqdori va qo'shgan odam
                  Row(
                    children: [
                      _buildSmallInfo(
                        icon: Icons.auto_awesome_motion_rounded,
                        text: '$qtyStr ${l10n.piece}',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildSmallInfo(
                        icon: Icons.person_rounded,
                        text: zakup['createdBy'] ?? l10n.unknown,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Narx va Vaqt (O'ng tomon)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  NumberFormatter.format(zakup['costPrice'] ?? 0),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: const Color.fromARGB(255, 39, 74, 173),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt), // Faqat vaqt yoki qisqa sana
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSmallInfo(
    {required IconData icon, required String text, required bool isDark}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: isDark ? Colors.white38 : Colors.black38),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black45,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
