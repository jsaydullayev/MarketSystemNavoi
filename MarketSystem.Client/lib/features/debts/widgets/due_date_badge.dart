// GAP-1 — display-only widget for the backend's nullable Debt.DueDate.
//
// Backend added the column in `feat(debt): add DueDate field to Debt entity`
// (commit 2e965e4) but has NO write endpoint yet — Flutter can read the
// value but can't set one. NotificationService and DashboardService already
// consume it internally for overdue classification; this widget brings the
// raw date to the debt-list and debt-detail surfaces so the owner can see
// what's driving those badges.
//
// Three render modes (chosen by the day delta from today's midnight):
//   • overdue      → danger pill: "Muddat o'tgan · 5 kun kechikkan"
//   • soon (≤2d)   → warning pill: "Bugun muddat" / "Ertaga muddat"
//   • upcoming     → neutral pill: "Muddat: 2026-06-01 · 12 kun qoldi"
//
// Returns SizedBox.shrink() when the input is null/unparseable — every
// call site can drop it in unconditionally and let the widget no-op for
// debts created before the column existed.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../l10n/app_localizations.dart';

enum _DueTone { danger, warning, neutral }

class DueDateBadge extends StatelessWidget {
  const DueDateBadge({
    super.key,
    required this.dueDate,
    this.compact = false,
    this.showAbsoluteDate = true,
  });

  /// Raw value from the debt map — usually `debt['dueDate']`. Accepts
  /// `String` (ISO-8601), `DateTime`, or `null`. Anything that doesn't
  /// parse cleanly is treated as null.
  final dynamic dueDate;

  /// When true, drops the absolute date prefix and renders just the
  /// relative pill ("Muddat o'tgan · 5 kun kechikkan"). Useful inside
  /// dense list cards where horizontal space is tight.
  final bool compact;

  /// When false, also drops the absolute date in non-compact mode.
  /// Useful when the card already prints the formatted date elsewhere.
  final bool showAbsoluteDate;

  /// Public helper so callers can roll their own UI (e.g. customer-level
  /// aggregate "any overdue?") without re-parsing.
  static DateTime? parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Public helper returning the integer day delta from today's midnight.
  /// Positive = future, 0 = today, negative = overdue. Returns null when
  /// the input doesn't parse.
  static int? daysUntil(dynamic raw) {
    final parsed = parse(raw);
    if (parsed == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(parsed.year, parsed.month, parsed.day);
    return due.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = parse(dueDate);
    if (parsed == null) return const SizedBox.shrink();

    final delta = daysUntil(dueDate)!;
    final tone = delta < 0
        ? _DueTone.danger
        : delta <= 2
        ? _DueTone.warning
        : _DueTone.neutral;

    final color = switch (tone) {
      _DueTone.danger => AppColors.danger,
      _DueTone.warning => AppColors.warning,
      _DueTone.neutral => context.colors.textSecondary,
    };

    final label = _label(l10n, delta);
    final formatted = showAbsoluteDate && !compact
        ? DateFormat('dd.MM.yyyy').format(parsed)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tone == _DueTone.danger
                ? Icons.error_outline_rounded
                : Icons.event_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs + 1),
          if (formatted != null) ...[
            Text(
              '${l10n.debtDueLabel}: $formatted',
              style: AppTextStyles.bodyMedium().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              ' · ',
              style: AppTextStyles.bodyMedium().copyWith(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
          Text(
            label,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Pick the right localized phrase for the delta. Centralised so every
  /// surface (badge, snackbar, alert) renders identical wording.
  String _label(AppLocalizations l10n, int delta) {
    if (delta < 0) {
      // Overdue — show absolute days, e.g. "Muddat o'tgan · 5 kun kechikkan".
      // For the compact case where the badge stands alone, fold the
      // headline into the days subtitle so we still read naturally.
      return compact
          ? '${l10n.debtOverdueBadge} · ${l10n.debtOverdueByDays(-delta)}'
          : '${l10n.debtOverdueBadge} · ${l10n.debtOverdueByDays(-delta)}';
    }
    if (delta == 0) return l10n.debtDueToday;
    if (delta == 1) return l10n.debtDueTomorrow;
    return l10n.debtDueInDays(delta);
  }
}
