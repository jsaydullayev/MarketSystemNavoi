// "Shubhali" tab for the security journal — flagged groups from
// GET /audit-logs/suspicious, with a red accent so they pop out from the
// routine entries. Extracted from security_journal_screen.dart as a pure
// code-move.

import 'package:flutter/material.dart';

import '../../../../data/services/audit_log_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'security_journal_format.dart';

class SuspiciousView extends StatefulWidget {
  const SuspiciousView({super.key, required this.service});

  final AuditLogService service;

  @override
  State<SuspiciousView> createState() => _SuspiciousViewState();
}

class _SuspiciousViewState extends State<SuspiciousView> {
  late Future<SuspiciousReport> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getSuspicious();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.service.getSuspicious();
    });
    await _future.catchError((_) => SuspiciousReport.empty());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<SuspiciousReport>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: context.colors.brand),
          );
        }
        final report = snapshot.data ?? SuspiciousReport.empty();
        if (report.isEmpty) {
          return RefreshIndicator(
            color: context.colors.brand,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl3,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 56,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.securityJournalNoSuspicious,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium().copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: context.colors.brand,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (report.failedLoginBursts.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.securityJournalFailedLoginBursts,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final burst in report.failedLoginBursts) ...[
                  _FailedLoginCard(burst: burst),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (report.bulkDeleteBursts.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.delete_sweep_rounded,
                  label: l10n.securityJournalBulkDeleteBursts,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final burst in report.bulkDeleteBursts) ...[
                  _BulkDeleteCard(burst: burst),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (report.recentErrors.isNotEmpty) ...[
                const _SectionHeader(
                  icon: Icons.bug_report_rounded,
                  label: 'Server xatoliklari',
                ),
                const SizedBox(height: AppSpacing.md),
                for (final err in report.recentErrors) ...[
                  _ErrorCard(error: err),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.danger),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.titleMedium().copyWith(
            color: AppColors.dangerDeep,
          ),
        ),
      ],
    );
  }
}

class _FailedLoginCard extends StatelessWidget {
  const _FailedLoginCard({required this.burst});

  final FailedLoginBurst burst;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DangerCard(
      titleRow: Row(
        children: [
          const Icon(Icons.person_off_rounded, color: AppColors.dangerStrong),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              burst.username,
              style: AppTextStyles.bodyLarge().copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dangerDeep,
              ),
            ),
          ),
          _CountBadge(count: burst.count),
        ],
      ),
      detailRows: [
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: l10n.securityJournalFirstSeen,
          value: formatTimestamp(burst.firstSeenUtc),
        ),
        _DetailRow(
          icon: Icons.update_rounded,
          label: l10n.securityJournalLastSeen,
          value: formatTimestamp(burst.lastSeenUtc),
        ),
        if (burst.ipAddresses.isNotEmpty)
          _DetailRow(
            icon: Icons.public_rounded,
            label: l10n.securityJournalSourceIps,
            value: burst.ipAddresses.join(', '),
            mono: true,
          ),
      ],
    );
  }
}

class _BulkDeleteCard extends StatelessWidget {
  const _BulkDeleteCard({required this.burst});

  final BulkDeleteBurst burst;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = burst.userName?.isNotEmpty == true
        ? burst.userName!
        : l10n.securityJournalAnonymousActor;
    return _DangerCard(
      titleRow: Row(
        children: [
          const Icon(Icons.delete_sweep_rounded, color: AppColors.dangerStrong),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              displayName,
              style: AppTextStyles.bodyLarge().copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dangerDeep,
              ),
            ),
          ),
          _CountBadge(count: burst.count),
        ],
      ),
      detailRows: [
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: l10n.securityJournalFirstSeen,
          value: formatTimestamp(burst.firstSeenUtc),
        ),
        _DetailRow(
          icon: Icons.update_rounded,
          label: l10n.securityJournalLastSeen,
          value: formatTimestamp(burst.lastSeenUtc),
        ),
        if (burst.entityTypes.isNotEmpty)
          _DetailRow(
            icon: Icons.category_rounded,
            label: l10n.securityJournalEntityTypes,
            value: burst.entityTypes.join(', '),
          ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final ErrorEntry error;

  @override
  Widget build(BuildContext context) {
    final where = [
      if (error.method?.isNotEmpty == true) error.method!,
      if (error.path?.isNotEmpty == true) error.path!,
    ].join(' ');
    return _DangerCard(
      titleRow: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bug_report_rounded, color: AppColors.dangerStrong),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              error.message.isNotEmpty ? error.message : 'Server xatoligi',
              style: AppTextStyles.bodyLarge().copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dangerDeep,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(code: error.statusCode),
        ],
      ),
      detailRows: [
        if (where.isNotEmpty)
          _DetailRow(
            icon: Icons.link_rounded,
            label: 'Manzil',
            value: where,
            mono: true,
          ),
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: 'Vaqt',
          value: formatTimestamp(error.createdAt),
        ),
        if (error.userName?.isNotEmpty == true)
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Kim',
            value: error.userName!,
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.code});
  final int code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$code',
        style: AppTextStyles.bodyMedium().copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.titleRow, required this.detailRows});

  final Widget titleRow;
  final List<Widget> detailRows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: AppSpacing.md),
          for (final row in detailRows) ...[
            row,
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '×$count',
        style: AppTextStyles.bodyMedium().copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.dangerStrong),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColors.dangerStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColors.dangerStrong,
              fontFamily: mono ? 'monospace' : null,
              fontSize: mono ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
