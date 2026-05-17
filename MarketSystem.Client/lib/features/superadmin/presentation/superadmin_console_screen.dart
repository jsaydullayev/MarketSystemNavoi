import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/superadmin_service.dart';
import '../domain/models/owner_summary.dart';
import '../domain/models/registration_request.dart';
import 'owner_detail_screen.dart';
import 'widgets/approve_request_dialog.dart';
import 'widgets/create_owner_dialog.dart';
import 'widgets/credentials_handoff_dialog.dart';
import 'widgets/reject_request_dialog.dart';

/// Hidden SuperAdmin console — design parity with the Figma prototype.
/// Two tabs: pending sign-up requests and Owners roster (with per-card
/// 3-dots menu → Detail/Edit/Block/Delete).
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
    _snack("Yangi owner yaratildi: ${created.username}", isError: false);
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
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!AppConfig.hasSuperAdminConsole) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.superAdminConsoleTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.report_outlined,
                    size: 56, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  l10n.superAdminConsoleNotConfigured,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.superAdminRebuildWithDartDefine,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _forceLogout,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
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
      backgroundColor: const Color(0xFFF0F4F9),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined,
                color: Color(0xFF1A73E8), size: 22),
            const SizedBox(width: 8),
            const Text('SuperAdmin Console',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'v1.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: _forceLogout,
            icon: const Icon(Icons.logout, size: 15),
            label: Text(l10n.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD93025),
              side: const BorderSide(color: Color(0xFFDADCE0)),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: const Color(0xFF1A73E8),
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: const Color(0xFF1A73E8),
              indicatorWeight: 2.5,
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
        ),
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
              label: const Text('Yangi Owner'),
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
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
    final color = selected
        ? const Color(0xFF1A73E8)
        : const Color(0xFF5F6368);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1A73E8)
                : const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF1A73E8),
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
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _ErrorState(error: error!, onRetry: onRefresh);
    final list = items ?? const <RegistrationRequest>[];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: c.maxWidth < 600 ? 4 : 2.2,
                children: [
                  _MiniStat(
                    label: 'KUTILMOQDA',
                    value: list.length.toString(),
                    color: const Color(0xFF856404),
                    subtitle: "Yangi so'rovlar",
                  ),
                  const _MiniStat(
                    label: 'TASDIQLANGAN',
                    value: '—',
                    color: Color(0xFF137333),
                    subtitle: 'Server stats kerak',
                  ),
                  const _MiniStat(
                    label: 'RAD ETILGAN',
                    value: '—',
                    color: Color(0xFFD93025),
                    subtitle: 'Server stats kerak',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "KUTILAYOTGAN SO'ROVLAR",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                _RefreshChip(onRefresh: onRefresh),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.superAdminNoPendingRequests,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...list.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(
                      request: req,
                      onApprove: () => onApprove(req),
                      onReject: () => onReject(req),
                    ),
                  )),
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
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
    return OutlinedButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh, size: 14),
      label: const Text('Yangilash'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: const BorderSide(color: Color(0xFFDADCE0)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFF1A73E8),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          request.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
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
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF7E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⏳ Kutilmoqda',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(request.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFDADCE0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 16),
                label: Text(l10n.superAdminReject),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD93025),
                  side: const BorderSide(color: Color(0xFFD93025)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 16),
                label: Text(l10n.superAdminApprove),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137333),
                  foregroundColor: Colors.white,
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
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _ErrorState(error: error!, onRetry: onRefresh);
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
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // FAB clearance
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDADCE0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: "Ism, username yoki do'kon nomi…",
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => searchCtrl.clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'FAOL EGALAR (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                _RefreshChip(onRefresh: onRefresh),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Yangi qo'shish"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👥', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        search.isNotEmpty
                            ? 'Hech narsa topilmadi'
                            : l10n.superAdminNoActiveOwners,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OwnerCard(
                    owner: o,
                    onTap: () => onTap(o),
                  ),
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
    final initial = owner.fullName.isNotEmpty
        ? owner.fullName[0].toUpperCase()
        : '?';
    final colors = _avatarColors(owner.userId);

    String statusLabel;
    Color statusColor;
    if (owner.isMarketBlocked) {
      statusLabel = 'Bloklangan';
      statusColor = const Color(0xFFD93025);
    } else if (owner.isActive) {
      statusLabel = 'Faol';
      statusColor = const Color(0xFF137333);
    } else {
      statusLabel = 'Faolsiz';
      statusColor = const Color(0xFF9AA0A6);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDADCE0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colors,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${owner.username}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    if (owner.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            owner.phone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (owner.marketName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏪',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          owner.marketName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  /// Deterministic per-owner colour so the same owner always gets the same
  /// avatar tint between sessions.
  Color _avatarColors(String userId) {
    final palette = [
      const Color(0xFF1A73E8),
      const Color(0xFF137333),
      const Color(0xFF7B1FA2),
      const Color(0xFFE65100),
      const Color(0xFF00695C),
      const Color(0xFFC5221F),
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
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
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
