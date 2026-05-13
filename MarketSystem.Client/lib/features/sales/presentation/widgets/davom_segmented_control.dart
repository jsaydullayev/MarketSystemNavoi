import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tabs in the Davom etayotgan screen. Default is `davom` — that's the
/// screen's whole reason for existing (resume a paused draft sale).
enum DavomTab { davom, qarz, paid, qarzdor }

class DavomTabSpec {
  final DavomTab tab;
  final String label;
  final int count;
  final Color color;

  const DavomTabSpec({
    required this.tab,
    required this.label,
    required this.count,
    required this.color,
  });
}

/// iOS-style segmented control + a colored summary card beneath it.
/// Switching tabs animates the slider underneath. The summary card swaps
/// its color and content based on the active tab.
class DavomSegmentedControl extends StatelessWidget {
  final DavomTab active;
  final List<DavomTabSpec> tabs;
  final ValueChanged<DavomTab> onChanged;

  /// Summary card payload — caller decides what shows under the segment.
  /// Typical: "2 ta · 78 000 so'm" for sales, "1 ta" for debtors.
  final String summaryLabel;
  final String summaryValue;

  const DavomSegmentedControl({
    super.key,
    required this.active,
    required this.tabs,
    required this.onChanged,
    required this.summaryLabel,
    required this.summaryValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = tabs.firstWhere((t) => t.tab == active).color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSegment(isDark),
        const SizedBox(height: 10),
        _buildSummary(isDark, activeColor),
      ],
    );
  }

  Widget _buildSegment(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: tabs
            .map((t) => Expanded(child: _buildOption(t, isDark)))
            .toList(),
      ),
    );
  }

  Widget _buildOption(DavomTabSpec t, bool isDark) {
    final isActive = t.tab == active;
    return GestureDetector(
      onTap: () => onChanged(t.tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF273349) : Colors.grey.shade100)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? t.color
                    : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              t.count.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? t.color.withOpacity(0.85)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            summaryLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              color: isDark ? Colors.white60 : Colors.grey[600],
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            summaryValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience: format a list of sales' totalAmount sum as `N ta · X XXX so'm`.
String formatSalesSummary(List<dynamic> sales) {
  if (sales.isEmpty) return '0 ta';
  final total = sales.fold<double>(
    0,
    (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0),
  );
  final amount =
      NumberFormat('#,###', 'en_US').format(total).replaceAll(',', ' ');
  return '${sales.length} ta · $amount so\'m';
}

String formatDebtorsSummary(List<dynamic> debtors) {
  return '${debtors.length} ta';
}
