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
import 'widgets/console_shared_widgets.dart';
import 'widgets/create_owner_dialog.dart';
import 'widgets/credentials_handoff_dialog.dart';
import 'widgets/owners_tab.dart';
import 'widgets/reject_request_dialog.dart';
import 'widgets/requests_tab.dart';

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
          RequestsTab(
            loading: _loadingRequests,
            error: _requestsError,
            items: _requests,
            onRefresh: _refreshRequests,
            onApprove: _onApprove,
            onReject: _onReject,
          ),
          OwnersTab(
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
              foregroundColor: context.colors.onBrand,
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
      shape: Border(bottom: BorderSide(color: context.colors.border, width: 1)),
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
                  unselectedLabelStyle: AppTextStyles.labelLarge().copyWith(
                    color: context.colors.textSecondary,
                  ),
                  tabs: [
                    Tab(
                      child: TabLabelBadge(
                        icon: Icons.assignment_outlined,
                        label: l10n.superAdminTabRequests,
                        count: pendingCount,
                        selected: _tabs.index == 0,
                      ),
                    ),
                    Tab(
                      child: TabLabelBadge(
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
