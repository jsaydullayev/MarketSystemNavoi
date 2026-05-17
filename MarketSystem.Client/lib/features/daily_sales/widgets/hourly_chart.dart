import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/data/models/profit_model.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Soatlik savdo bar chart — bucketed in 2-hour windows (12 bars for 24h).
///
/// Computed entirely client-side from the same `sales[]` list that's already
/// loaded by the screen — no extra API call, no extra error surface. Empty
/// hours render as low-opacity stubs so the axis stays legible.
class HourlyChart extends StatelessWidget {
  final List<DailySalesListItemModel> sales;

  /// 2-hour buckets keep the chart readable on phone widths.
  static const int _bucketCount = 12;
  static const int _hoursPerBucket = 24 ~/ _bucketCount;

  const HourlyChart({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final buckets = _bucketize(sales);
    final maxValue =
        buckets.fold<double>(0, (m, v) => v > m ? v : m); // 0 if all empty
    final hasAnyData = maxValue > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                l10n.hourlySales,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!hasAnyData)
                Text(
                  l10n.noData,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_bucketCount, (i) {
                final v = buckets[i];
                final startHour = i * _hoursPerBucket;
                final endHour = startHour + _hoursPerBucket;
                // When all empty, render uniform low stubs (15%). When some
                // data exists, scale to the max so the tallest is ~100%.
                final ratio = hasAnyData
                    ? (maxValue == 0 ? 0.0 : (v / maxValue).clamp(0.0, 1.0))
                    : 0.15;
                final isHighlighted = hasAnyData && v == maxValue && v > 0;
                final tooltipMsg = v > 0
                    ? '${startHour.toString().padLeft(2, '0')}:00–'
                        '${endHour.toString().padLeft(2, '0')}:00\n'
                        '${_fmtMoney(v)} ${l10n.currencySom}'
                    : '${startHour.toString().padLeft(2, '0')}:00–'
                        '${endHour.toString().padLeft(2, '0')}:00\n'
                        '${l10n.noData}';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: tooltipMsg,
                      preferBelow: false,
                      waitDuration: const Duration(milliseconds: 120),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF28C33).withValues(alpha: 0.4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: ratio.isFinite
                              ? (ratio < 0.06 && hasAnyData && v > 0
                                  ? 0.06
                                  : (ratio < 0.05 ? 0.05 : ratio))
                              : 0.05,
                          widthFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? const Color(0xFFF28C33)
                                  : (hasAnyData && v > 0
                                      ? const Color(0xFFF28C33).withValues(alpha: 0.55)
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(alpha: 0.06))),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(_bucketCount, (i) {
              final startHour = i * _hoursPerBucket;
              // Show every 3rd bucket label (0h, 6h, 12h, 18h) to avoid clutter
              final showLabel = i % 3 == 0;
              return Expanded(
                child: Text(
                  showLabel ? '${startHour}h' : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _fmtMoney(double n) =>
      NumberFormat('#,###', 'en_US').format(n).replaceAll(',', ' ');

  /// Sum totalAmount per 2-hour bucket. Never throws — defensive against
  /// out-of-range hours (e.g. timezone weirdness) by clamping into [0, 11].
  List<double> _bucketize(List<DailySalesListItemModel> all) {
    final out = List<double>.filled(_bucketCount, 0);
    for (final s in all) {
      final h = s.createdAt.hour;
      final idx = (h ~/ _hoursPerBucket).clamp(0, _bucketCount - 1);
      out[idx] += s.totalAmount;
    }
    return out;
  }
}
