// Shared date formatter for the owner-detail screen and its widget files.
// Extracted verbatim from owner_detail_screen.dart so the hero card,
// info cards, and the screen itself can all reuse the same logic.

String formatOwnerDetailDate(DateTime utc, {bool withTime = true}) {
  final local = utc.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  final date = '${local.year}-${two(local.month)}-${two(local.day)}';
  if (!withTime) return date;
  return '$date ${two(local.hour)}:${two(local.minute)}';
}
