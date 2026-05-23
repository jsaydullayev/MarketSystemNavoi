// Hidden SuperAdmin console — migrated to the new design system.
// Two tabs: pending sign-up requests and Owners roster (with per-card
// Detail / Edit / Block / Delete actions). All business logic (refresh,
// approve, reject, create, block, delete via SuperAdminService) and role
// gating are preserved from the original implementation.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/superadmin_service.dart';
import '../domain/models/owner_summary.dart';
import '../domain/models/registration_request.dart';
import 'owner_detail_screen.dart';
import 'widgets/approve_request_dialog.dart';
import 'widgets/create_owner_dialog.dart';
import 'widgets/credentials_handoff_dialog.dart';
import 'widgets/reject_request_dialog.dart';

class SuperAdminConsoleScreen extends StatefulWidget {
  const SuperAdminConsoleScreen({super.key});

  @override
  State<SuperAdminConsoleScreen> createState() =>
      _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final SuperAdminService _service;
  final _searchCtrl = TextEditingController();

  List<RegistrationRequest>? _requests;
  List<OwnerSummary>? _owners;
  bool _loadingRequests = false;
  bool _loadingOwners = false;
  String? _requestsError;
  String? _ownersError;
  String _ownerSearch = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final auth = context.read<AuthProvider>();
    _service = SuperAdminService(auth.httpService);
    _searchCtrl.addListener(() {
      setState(() => _ownerSearch = _searchCtrl.text.toLowerCase());
    });

    // Defence in depth: bounce non-SuperAdmin out before any UI renders.
    final role = auth.user?['role'] as String?;
    if (!auth.isAuthenticated || role != 'SuperAdmin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      });
      return;
    }

    if (!AppConfig.hasSuperAdminConsole) return;
    _refreshRequests();
    _refreshOwners();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _loadingRequests = true;
      _requestsError = null;
    });
    final res = await _service.listRequests(status: 'Pending');
    if (!mounted) return;
    setState(() {
      _loadingRequests = false;
      if (res.status == SuperAdminOpStatus.success) {
        _requests = res.data ?? const [];
      } else {
        _requestsError = res.message ?? 'failure';
      }
    });
  }

  Future<void> _refreshOwners() async {
    setState(() {
      _loadingOwners = true;
      _ownersError = null;
    });
    final res = await _service.listOwners();
    if (!mounted) return;
    setState(() {
      _loadingOwners = false;
      if (res.status == SuperAdminOpStatus.success) {
        _owners = res.data ?? const [];
      } else {
        _ownersError = res.message ?? 'failure';
      }
    });
  }

  Future<void> _onApprove(RegistrationRequest req) async {
    final approved = await showDialog<ApproveResult>(
      context: context,
      builder: (_) => ApproveRequestDialog(request: req),
    );
    if (approved == null || !mounted) return;

    final res = await _service.approve(
      requestId: req.id,
      username: approved.username,
      password: approved.password,
      marketName: approved.marketName,
      subdomain: approved.subdomain,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (res.status == SuperAdminOpStatus.success) {
      _refreshRequests();
      _refreshOwners();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CredentialsHandoffDialog(
          username: approved.username,
          password: approved.password,
          marketName: approved.marketName,
        ),
      );
      if (!mounted) return;
      _snack(l10n.superAdminApproveSuccess(approved.username), isError: false);
    } else if (res.status == SuperAdminOpStatus.unauthorized) {
      await _forceLogout();
    } else {
      _snack(res.message ?? l10n.superAdminApproveFailed, isError: true);
    }
  }

  Future<void> _onReject(RegistrationRequest req) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => RejectRequestDialog(request: req),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    final res = await _service.reject(requestId: req.id, reason: reason);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (res.status == SuperAdminOpStatus.success) {
      _snack(l10n.superAdminRejectSuccess, isError: false);
      _refreshRequests();
    } else {
      _snack(res.message ?? l10n.superAdminRejectFailed, isError: true);
    }
  }

  Future<void> _onCreateOwner() async {
    final created = await showDialog<CreatedOwnerResult>(
      context: context,
      builder: (_) => const CreateOwnerDialog(),
    );
    if (created == null || !mounted) return;
    _refreshOwners();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CredentialsHandoffDialog(
        username: created.username,
        password: created.password,
        marketName: created.marketName,
      ),
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _snack(l10n.newOwnerCreated(created.username), isError: false);
  }

  Future<void> _onOwnerTap(OwnerSummary owner) async {
    final refreshNeeded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerDetailScreen(userId: owner.userId),
      ),
    );
    if (refreshNeeded == true && mounted) _refreshOwners();
  }

  Future<void> _forceLogout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _snack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!AppConfig.hasSuperAdminConsole) {
      return Scaffold(
        backgroundColor: context.colors.bg,
        appBar: _buildAppBar(context, l10n, withTabs: false),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.report_outlined,
                  size: 56,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.superAdminConsoleNotConfigured,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.superAdminRebuildWithDartDefine,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(),
                ),
                const SizedBox(height: AppSpacing.xl3),
                SizedBox(
                  width: 220,
                  child: AppSecondaryButton(
                    onPressed: _forceLogout,
                    icon: Icons.logout,
                    label: l10n.logout,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pendingCount = _requests?.length ?? 0;
    final ownersCount = _owners?.length ?? 0;

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: _buildAppBar(
        context,
        l10n,
        withTabs: true,
        pendingCount: pendingCount,
        ownersCount: ownersCount,
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RequestsTab(
            loading: _loadingRequests,
            error: _requestsError,
            items: _requests,
            onRefresh: _refreshRequests,
            onApprove: _onApprove,
            onReject: _onReject,
          ),
          _OwnersTab(
            loading: _loadingOwners,
            error: _ownersError,
            items: _owners,
            search: _ownerSearch,
            searchCtrl: _searchCtrl,
            onRefresh: _refreshOwners,
            onTap: _onOwnerTap,
            onCreate: _onCreateOwner,
          ),
        ],
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(
              onPressed: _onCreateOwner,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.newOwner),
              backgroundColor: context.colors.brand,
              foregroundColor: Colors.white,
              elevation: 2,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n, {
    required bool withTabs,
    int pendingCount = 0,
    int ownersCount = 0,
  }) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: context.colors.surface,
      foregroundColor: context.colors.text,
      shape: Border(
        bottom: BorderSide(color: context.colors.border, width: 1),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: context.colors.brand,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            l10n.superAdminConsoleTitleShort,
            style: AppTextStyles.titleMedium(),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: SizedBox(
            width: 130,
            child: AppSecondaryButton(
              onPressed: _forceLogout,
              icon: Icons.logout,
              label: l10n.logout,
            ),
          ),
        ),
      ],
      bottom: withTabs
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: ColoredBox(
                color: context.colors.surface,
                child: TabBar(
                  controller: _tabs,
                  labelColor: context.colors.brand,
                  unselectedLabelColor: context.colors.textSecondary,
                  indicatorColor: context.colors.brand,
                  indicatorWeight: 2.5,
                  labelStyle: AppTextStyles.labelLarge(),
                  unselectedLabelStyle: AppTextStyles.labelLarge()
                      .copyWith(color: context.colors.textSecondary),
                  tabs: [
                    Tab(
                      child: _TabLabel(
                        icon: Icons.assignment_outlined,
                        label: l10n.superAdminTabRequests,
                        count: pendingCount,
                        selected: _tabs.index == 0,
                      ),
                    ),
                    Tab(
                      child: _TabLabel(
                        icon: Icons.people_outline,
                        label: l10n.superAdminTabOwners,
                        count: ownersCount,
                        selected: _tabs.index == 1,
                      ),
                    ),
                  ],
                  onTap: (_) => setState(() {}),
                ),
              ),
            )
          : null,
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.brand : context.colors.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.md),
        Text(label),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: selected ? context.colors.brand : context.colors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? context.colors.onBrand
                  : context.colors.brand,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });
  final bool loading;
  final String? error;
  final List<RegistrationRequest>? items;
  final Future<void> Function() onRefresh;
  final Future<void> Function(RegistrationRequest) onApprove;
  final Future<void> Function(RegistrationRequest) onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.brand),
      );
    }
    if (error case final err?) return _ErrorState(error: err, onRetry: onRefresh);
    final list = items ?? const <RegistrationRequest>[];

    return RefreshIndicator(
      color: context.colors.brand,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats row — counts come from the live list; "approved/rejected
            // this month" require a server-side aggregate we don't surface yet.
            LayoutBuilder(
              builder: (ctx, c) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: c.maxWidth < 600 ? 1 : 3,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: c.maxWidth < 600 ? 4 : 2.2,
                children: [
                  _MiniStat(
                    label: l10n.superAdminPending.toUpperCase(),
                    value: list.length.toString(),
                    color: AppColors.warning,
                    subtitle: l10n.superAdminNewRequests,
                  ),
                  _MiniStat(
                    label: l10n.superAdminApproved,
                    value: '—',
                    color: AppColors.success,
                    subtitle: l10n.superAdminServerStatsNeeded,
                  ),
                  _MiniStat(
                    label: l10n.superAdminRejected,
                    value: '—',
                    color: AppColors.danger,
                    subtitle: l10n.superAdminServerStatsNeeded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.superAdminPendingRequestsHeader,
                    style: AppTextStyles.caption().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                _RefreshChip(onRefresh: onRefresh),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (list.isEmpty)
              _EmptyState(
                icon: Icons.assignment_outlined,
                text: l10n.superAdminNoPendingRequests,
              )
            else
              ...list.map(
                (req) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _RequestCard(
                    request: req,
                    onApprove: () => onApprove(req),
                    onReject: () => onReject(req),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl3),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption()
                .copyWith(color: context.colors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(subtitle, style: AppTextStyles.bodySmall()),
        ],
      ),
    );
  }
}

class _RefreshChip extends StatelessWidget {
  const _RefreshChip({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh, size: 14),
      label: Text(l10n.refresh),
      style: TextButton.styleFrom(
        foregroundColor: context.colors.textSecondary,
        textStyle: AppTextStyles.bodySmall().copyWith(fontSize: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: context.colors.border),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 32, color: context.colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(text, style: AppTextStyles.bodyMedium()),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });
  final RegistrationRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial = request.fullName.isNotEmpty
        ? request.fullName[0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg + 2,
        AppSpacing.xl,
        AppSpacing.lg + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.brand,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.labelLarge()
                      .copyWith(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName,
                      style: AppTextStyles.labelLarge().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          request.phone,
                          style: AppTextStyles.bodySmall(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md + 2,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 11,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.superAdminPending,
                          style: AppTextStyles.bodySmall().copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formatDate(request.createdAt),
                    style: AppTextStyles.bodySmall().copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: context.colors.border),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppDangerButton(
                  label: l10n.superAdminReject,
                  icon: Icons.close,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppPrimaryButton(
                  label: l10n.superAdminApprove,
                  icon: Icons.check,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnersTab extends StatelessWidget {
  const _OwnersTab({
    required this.loading,
    required this.error,
    required this.items,
    required this.search,
    required this.searchCtrl,
    required this.onRefresh,
    required this.onTap,
    required this.onCreate,
  });
  final bool loading;
  final String? error;
  final List<OwnerSummary>? items;
  final String search;
  final TextEditingController searchCtrl;
  final Future<void> Function() onRefresh;
  final Future<void> Function(OwnerSummary) onTap;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.brand),
      );
    }
    if (error case final err?) return _ErrorState(error: err, onRetry: onRefresh);
    final all = items ?? const <OwnerSummary>[];
    final filtered = search.isEmpty
        ? all
        : all.where((o) {
            final s = search;
            return o.fullName.toLowerCase().contains(s) ||
                o.username.toLowerCase().contains(s) ||
                (o.marketName ?? '').toLowerCase().contains(s) ||
                (o.phone ?? '').toLowerCase().contains(s);
          }).toList();

    return RefreshIndicator(
      color: context.colors.brand,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          96, // FAB clearance
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: context.colors.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: context.colors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.ownerSearchHint,
                        hintStyle: AppTextStyles.bodyMedium().copyWith(
                          color: context.colors.textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                      ),
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: context.colors.textSecondary,
                      onPressed: () => searchCtrl.clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.superAdminActiveOwnersHeader(filtered.length),
                    style: AppTextStyles.caption().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                _RefreshChip(onRefresh: onRefresh),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 160,
                  child: AppPrimaryButton(
                    onPressed: onCreate,
                    icon: Icons.add,
                    label: l10n.addNew,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (filtered.isEmpty)
              _EmptyState(
                icon: Icons.people_outline,
                text: search.isNotEmpty
                    ? l10n.nothingFound
                    : l10n.superAdminNoActiveOwners,
              )
            else
              ...filtered.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
                  child: _OwnerCard(owner: o, onTap: () => onTap(o)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.onTap});
  final OwnerSummary owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial =
        owner.fullName.isNotEmpty ? owner.fullName[0].toUpperCase() : '?';
    final avatarColor = _avatarColor(context, owner.userId);

    Color statusColor;
    Color statusBg;
    String statusLabel;
    if (owner.isMarketBlocked) {
      statusLabel = l10n.statusBlocked;
      statusColor = AppColors.danger;
      statusBg = AppColors.dangerLight;
    } else if (owner.isActive) {
      statusLabel = l10n.statusActive;
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
    } else {
      statusLabel = l10n.statusInactive;
      statusColor = context.colors.textMuted;
      statusBg = context.colors.inputFill;
    }

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.labelLarge()
                      .copyWith(color: Colors.white, fontSize: 17),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.fullName,
                      style: AppTextStyles.labelLarge().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${owner.username}',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: context.colors.brand,
                        fontSize: 13,
                      ),
                    ),
                    if (owner.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            // Phone reaches this branch via an outer
                            // `if (owner.phone != null)` guard — but field
                            // access doesn't promote, so the safer shape is
                            // the null-aware default.
                            owner.phone ?? '',
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (owner.marketName case final marketName?)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            marketName,
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.colors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: AppTextStyles.bodySmall().copyWith(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.chevron_right,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Deterministic per-owner colour so the same owner always gets the same
  /// avatar tint between sessions.
  Color _avatarColor(BuildContext context, String userId) {
    final palette = [
      context.colors.brand,
      AppColors.success,
      const Color(0xFF7C3AED), // purple
      const Color(0xFF0EA5E9), // sky
      const Color(0xFFEC4899), // pink
      AppColors.warning,
    ];
    final hash = userId.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return palette[hash % palette.length];
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = error == 'console_not_configured'
        ? l10n.superAdminConsoleNotConfigured
        : l10n.superAdminLoadFailed;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 220,
              child: AppPrimaryButton(
                onPressed: onRetry,
                icon: Icons.refresh,
                label: l10n.retry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime utc) {
  final local = utc.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  return '${local.year}-${two(local.month)}-${two(local.day)}  ${two(local.hour)}:${two(local.minute)}';
}
