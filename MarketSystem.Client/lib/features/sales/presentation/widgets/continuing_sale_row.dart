import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact row used in the B1 (4-segment) Davom etayotgan screen.
/// One row per sale, status shown as a 4-px left strip (no chip), customer
/// avatar + name primary, amount on the right. Tap = primary action,
/// trailing icon = delete.
class ContinuingSaleRow extends StatelessWidget {
  final dynamic sale; // raw map from API
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Optional small pill next to the customer name. Used for Draft sales
  /// to nudge the seller ("DAVOM" — you can pick this back up).
  final String? hintLabel;

  /// Strip color (status accent on the left).
  final Color stripColor;

  /// Amount text color (matches the strip for visual cohesion).
  final Color amountColor;

  const ContinuingSaleRow({
    super.key,
    required this.sale,
    required this.onTap,
    required this.onDelete,
    required this.stripColor,
    required this.amountColor,
    this.hintLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customerName = (sale['customerName'] as String?)?.trim();
    final hasCustomer = customerName != null && customerName.isNotEmpty;
    final String displayName = hasCustomer ? customerName : 'Mijozsiz';

    final id = (sale['id'] as String?) ?? '';
    final shortId = id.length >= 8
        ? '#${id.substring(0, 8).toUpperCase()}'
        : '#${id.toUpperCase()}';

    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final itemsCount = (sale['items'] as List<dynamic>?)?.length ?? 0;

    final createdAtRaw = sale['createdAt'];
    String timeStr = '';
    if (createdAtRaw != null) {
      try {
        final dt = DateTime.parse(createdAtRaw.toString());
        timeStr = DateFormat('d.M HH:mm').format(dt);
      } catch (_) {/* fall through to empty string */}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left status strip
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: stripColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                  ),
                  // Middle content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _Avatar(
                                name: hasCustomer ? displayName : null,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hintLabel != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: stripColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    hintLabel!,
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: stripColor,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(
                                shortId,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (itemsCount > 0) ...[
                                Text(
                                  '$itemsCount ta',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _Dot(isDark: isDark),
                                const SizedBox(width: 6),
                              ],
                              if (timeStr.isNotEmpty)
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right: amount + delete icon
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(totalAmount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: amountColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'so\'m',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DeleteButton(onTap: onDelete, isDark: isDark),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(double n) =>
      NumberFormat('#,###', 'en_US').format(n).replaceAll(',', ' ');
}

class _Avatar extends StatelessWidget {
  final String? name;
  final bool isDark;

  const _Avatar({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.trim().isNotEmpty;
    final initial = hasName ? name!.trim()[0].toUpperCase() : '?';
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasName
            ? const Color(0xFFF28C33).withOpacity(0.16)
            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: hasName
              ? const Color(0xFFF28C33)
              : (isDark ? Colors.white54 : Colors.grey),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isDark;
  const _Dot({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: isDark ? Colors.white38 : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _DeleteButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFEF4444),
            size: 16,
          ),
        ),
      ),
    );
  }
}
