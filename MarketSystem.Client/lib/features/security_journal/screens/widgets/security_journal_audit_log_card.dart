// Single audit-log row card for the "Hammasi" tab. Extracted from
// security_journal_screen.dart as a pure code-move.

import 'package:flutter/material.dart';

import '../../../../data/services/audit_log_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'security_journal_format.dart';

class AuditLogCard extends StatelessWidget {
  const AuditLogCard({super.key, required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final isHighRisk = _isHighRiskAction(entry.action);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isHighRisk ? AppColors.dangerLight : c.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  entry.action,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w700,
                    color: isHighRisk ? AppColors.dangerDeep : c.brandDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  entry.entityType,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatTimestamp(entry.createdAt),
                style: AppTextStyles.bodyMedium().copyWith(
                  color: c.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  entry.userName?.isNotEmpty == true
                      ? entry.userName!
                      : l10n.securityJournalAnonymousActor,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: c.textSecondary,
                    fontStyle: entry.userName?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              if (entry.ipAddress case final ip? when ip.isNotEmpty) ...[
                Icon(Icons.public_rounded, size: 14, color: c.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  ip,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: c.textMuted,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          if (entry.payload.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _previewPayload(entry.payload),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium().copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Anything that signals an account-takeover attempt or a privileged
  /// change gets the danger pill instead of the brand pill. G6 — added
  /// PasswordChange (credential mutation; review for plausibility against
  /// the actor's normal pattern) and ShiftChange (admin gating a seller's
  /// ability to log in; misuse can lock out the till outside hours).
  bool _isHighRiskAction(String action) => switch (action) {
    'LoginFailed' ||
    'Delete' ||
    'PermissionChange' ||
    'Block' ||
    'PasswordChange' ||
    'ShiftChange' => true,
    _ => false,
  };

  String _previewPayload(String raw) {
    // Collapse the JSON to one line; the screen renders monospaced so newlines
    // would just produce ragged whitespace. The card itself wraps to maxLines: 2.
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
