// Shared formatting helpers for the security journal screen.

/// Compact, locale-neutral timestamp ("HH:mm · dd.MM.yyyy"). The audit
/// reviewer cares about precise time, not pretty "5 min ago" phrasing.
String formatTimestamp(DateTime when) {
  String two(int n) => n.toString().padLeft(2, '0');
  final local = when.isUtc ? when.toLocal() : when;
  return '${two(local.hour)}:${two(local.minute)} · '
      '${two(local.day)}.${two(local.month)}.${local.year}';
}
