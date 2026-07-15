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
          ..._buildPayloadRows(),
        ],
      ),
    );
  }

  /// Readable payload — labeled chips ("Soni: 3", "Jami summa: 130 000 so'm")
  /// instead of the raw JSON with GUIDs the reviewer can't interpret. Empty
  /// when the payload carries nothing worth showing.
  List<Widget> _buildPayloadRows() {
    final rows = readablePayloadRows(entry.payload);
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (label, value) in rows)
            _PayloadChip(label: label, value: value),
        ],
      ),
    ];
  }

  /// High-risk actions get the danger pill (account-takeover / privileged
  /// change) instead of the brand pill.
  bool _isHighRiskAction(String action) => switch (action) {
    'LoginFailed' ||
    'Delete' ||
    'PermissionChange' ||
    'Block' ||
    'PasswordChange' ||
    'ShiftChange' ||
    'Error' => true,
    _ => false,
  };
}

/// A single "label: value" pill from the audit payload.
class _PayloadChip extends StatelessWidget {
  const _PayloadChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.borderSoft),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.bodySmall().copyWith(
                color: c.textMuted,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodySmall().copyWith(
                color: c.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
