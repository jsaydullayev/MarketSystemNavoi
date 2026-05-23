// Owner / SuperAdmin "Xavfsizlik jurnali" screen — Plan 07 Bosqich 4.
//
// Two tabs:
//   • "Hammasi"   — paged audit log with EntityType / Action filter chips.
//   • "Shubhali"  — flagged groups from GET /audit-logs/suspicious, with a
//                   red accent so they pop out from the routine entries.
//
// Tenant scoping happens server-side (data.auditLog + role check). The
// Drawer entry on the dashboard is gated by `context.can('data.auditLog')`,
// which is true for Owner, SuperAdmin and any Admin the Owner granted.

import 'package:flutter/material.dart';

import '../../../data/services/audit_log_service.dart';
import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';

/// Static catalogues for the filter chips. Kept untranslated — these are
/// canonical EntityType / Action keys the server stores verbatim, and the
/// "audit reviewer" persona is technical enough to read them.
const _entityTypes = <String>[
  'Sale',
  'Payment',
  'Zakup',
  'Debt',
  'Auth',
  'User',
  'Permission',
  'Market',
  'CashRegister',
  'Shift',
  'RegistrationRequest',
];

// G6 — must stay in lockstep with `MarketSystem.Domain/Constants/AuditEvents.cs`
// `AuditActions`. The backend will EMIT any action it lists; whatever isn't
// in this filter chip-list is still rendered as a row, just unfilterable.
// Last sync with backend Y1: added Deposit (cash AddCash), PasswordChange
// (UpdateProfile w/ new password), ShiftChange (admin sets seller shift),
// ProfileImageUpdate (avatar set/clear).
const _actions = <String>[
  'Create',
  'Update',
  'Delete',
  'Cancel',
  'Login',
  'LoginFailed',
  'Logout',
  'Activate',
  'Deactivate',
  'PermissionChange',
  'Block',
  'Unblock',
  'Withdraw',
  'Deposit',
  'Open',
  'Close',
  'PasswordChange',
  'ShiftChange',
  'ProfileImageUpdate',
];

class SecurityJournalScreen extends StatefulWidget {
  const SecurityJournalScreen({super.key});

  @override
  State<SecurityJournalScreen> createState() => _SecurityJournalScreenState();
}

class _SecurityJournalScreenState extends State<SecurityJournalScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final AuditLogService _service = AuditLogService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          l10n.securityJournal,
          style: AppTextStyles.titleMedium(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.brand,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: context.colors.brand,
          labelStyle: AppTextStyles.bodyLarge(),
          tabs: [
            Tab(text: l10n.securityJournalAllTab),
            Tab(text: l10n.securityJournalSuspiciousTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllAuditLogsView(service: _service),
          _SuspiciousView(service: _service),
        ],
      ),
    );
  }
}

// ─── "All" tab ────────────────────────────────────────────────────────

class _AllAuditLogsView extends StatefulWidget {
  const _AllAuditLogsView({required this.service});

  final AuditLogService service;

  @override
  State<_AllAuditLogsView> createState() => _AllAuditLogsViewState();
}

class _AllAuditLogsViewState extends State<_AllAuditLogsView> {
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final List<AuditLogEntry> _items = [];

  int _page = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _initialFetchDone = false;

  String? _entityTypeFilter;
  String? _actionFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _page >= _totalPages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _items.clear();
      _page = 1;
      _totalPages = 1;
      _isLoading = true;
    });
    final result = await widget.service.list(
      entityType: _entityTypeFilter,
      action: _actionFilter,
      page: 1,
      size: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _isLoading = false;
      _initialFetchDone = true;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final next = _page + 1;
    final result = await widget.service.list(
      entityType: _entityTypeFilter,
      action: _actionFilter,
      page: next,
      size: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  }

  Future<void> _refresh() => _loadFirst();

  void _setEntityType(String? value) {
    if (value == _entityTypeFilter) return;
    _entityTypeFilter = value;
    _loadFirst();
  }

  void _setAction(String? value) {
    if (value == _actionFilter) return;
    _actionFilter = value;
    _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _FilterStrip(
          label: l10n.securityJournalFilterEntityType,
          options: _entityTypes,
          selected: _entityTypeFilter,
          onChanged: _setEntityType,
        ),
        _FilterStrip(
          label: l10n.securityJournalFilterAction,
          options: _actions,
          selected: _actionFilter,
          onChanged: _setAction,
        ),
        Divider(color: context.colors.borderSoft, height: 1),
        Expanded(child: _buildBody(l10n)),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (!_initialFetchDone && _isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.brand),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: context.colors.brand,
        onRefresh: _refresh,
        // A ListView with one item is the standard "empty state inside a
        // refresh indicator" trick — without something scrollable, the pull
        // gesture never fires.
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
                child: Text(
                  l10n.securityJournalEmptyAll,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: context.colors.textMuted,
                  ),
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
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_page < _totalPages ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            // Loading footer for "next page in flight".
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.colors.brand,
                  ),
                ),
              ),
            );
          }
          return _AuditLogCard(entry: _items[index]);
        },
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: l10n.securityJournalFilterAll,
                  selected: selected == null,
                  onTap: () => onChanged(null),
                ),
                for (final opt in options)
                  _Chip(
                    label: opt,
                    selected: selected == opt,
                    onTap: () => onChanged(opt),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? c.brand : c.inputFill,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected ? c.brand : c.border,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium().copyWith(
              color: selected ? c.onBrand : c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.entry});

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
                  color: isHighRisk
                      ? AppColors.dangerLight
                      : c.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  entry.action,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w700,
                    color: isHighRisk
                        ? AppColors.dangerDeep
                        : c.brandDark,
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
                _formatTimestamp(entry.createdAt),
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
        'ShiftChange' =>
          true,
        _ => false,
      };

  String _previewPayload(String raw) {
    // Collapse the JSON to one line; the screen renders monospaced so newlines
    // would just produce ragged whitespace. The card itself wraps to maxLines: 2.
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// ─── "Suspicious" tab ─────────────────────────────────────────────────

class _SuspiciousView extends StatefulWidget {
  const _SuspiciousView({required this.service});

  final AuditLogService service;

  @override
  State<_SuspiciousView> createState() => _SuspiciousViewState();
}

class _SuspiciousViewState extends State<_SuspiciousView> {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
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
          value: _formatTimestamp(burst.firstSeenUtc),
        ),
        _DetailRow(
          icon: Icons.update_rounded,
          label: l10n.securityJournalLastSeen,
          value: _formatTimestamp(burst.lastSeenUtc),
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
          value: _formatTimestamp(burst.firstSeenUtc),
        ),
        _DetailRow(
          icon: Icons.update_rounded,
          label: l10n.securityJournalLastSeen,
          value: _formatTimestamp(burst.lastSeenUtc),
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

// ─── Helpers ──────────────────────────────────────────────────────────

/// Compact, locale-neutral timestamp ("HH:mm · dd.MM.yyyy"). The audit
/// reviewer cares about precise time, not pretty "5 min ago" phrasing.
String _formatTimestamp(DateTime when) {
  String two(int n) => n.toString().padLeft(2, '0');
  final local = when.isUtc ? when.toLocal() : when;
  return '${two(local.hour)}:${two(local.minute)} · '
      '${two(local.day)}.${two(local.month)}.${local.year}';
}
