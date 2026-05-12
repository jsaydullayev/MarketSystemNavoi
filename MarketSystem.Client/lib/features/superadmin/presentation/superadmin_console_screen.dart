import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/superadmin_service.dart';
import '../domain/models/owner_summary.dart';
import '../domain/models/registration_request.dart';
import 'widgets/approve_request_dialog.dart';
import 'widgets/credentials_handoff_dialog.dart';
import 'widgets/reject_request_dialog.dart';

/// Hidden SuperAdmin console.
///
/// Two tabs: pending sign-up requests (review + approve / reject) and active
/// Owner roster. Auto-navigated to from the login flow when the user's JWT
/// carries `Role == SuperAdmin`; not reachable from any visible navigation.
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

  // Each tab holds its own data so switching tabs doesn't blow away the
  // other's already-loaded list.
  List<RegistrationRequest>? _requests;
  List<OwnerSummary>? _owners;
  bool _loadingRequests = false;
  bool _loadingOwners = false;
  String? _requestsError;
  String? _ownersError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final auth = context.read<AuthProvider>();
    _service = SuperAdminService(auth.httpService);

    // Defence in depth: the route is supposed to be unreachable from any
    // visible navigation, but if a non-SuperAdmin somehow lands here (typed
    // URL, deep link) we bounce them back to /login before they see any UI.
    // The backend would 401/404 their API calls regardless, but rendering
    // the console shell would still leak that the surface exists.
    final role = auth.user?['role'] as String?;
    if (!auth.isAuthenticated || role != 'SuperAdmin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      });
      return;
    }

    // Configuration check up here too, so we don't fire two HTTP requests in
    // initState when the console segment is missing (service short-circuits
    // them anyway, but the loading→error→loading flicker on the build is
    // distracting). The build() path will render the "not configured" view.
    if (!AppConfig.hasSuperAdminConsole) return;

    _refreshRequests();
    _refreshOwners();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _loadingRequests = true;
      _requestsError = null;
    });
    final result = await _service.listRequests(status: 'Pending');
    if (!mounted) return;
    setState(() {
      _loadingRequests = false;
      if (result.status == SuperAdminOpStatus.success) {
        _requests = result.data ?? const [];
      } else {
        _requestsError = result.message ?? 'failure';
      }
    });
  }

  Future<void> _refreshOwners() async {
    setState(() {
      _loadingOwners = true;
      _ownersError = null;
    });
    final result = await _service.listOwners();
    if (!mounted) return;
    setState(() {
      _loadingOwners = false;
      if (result.status == SuperAdminOpStatus.success) {
        _owners = result.data ?? const [];
      } else {
        _ownersError = result.message ?? 'failure';
      }
    });
  }

  Future<void> _onApprove(RegistrationRequest request) async {
    final approved = await showDialog<ApproveResult>(
      context: context,
      builder: (_) => ApproveRequestDialog(request: request),
    );
    if (approved == null || !mounted) return;

    final result = await _service.approve(
      requestId: request.id,
      username: approved.username,
      password: approved.password,
      marketName: approved.marketName,
      subdomain: approved.subdomain,
    );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (result.status == SuperAdminOpStatus.success) {
      _refreshRequests();
      _refreshOwners(); // Newly created owner shows up here.
      // Show the credentials in a copyable dialog BEFORE the success snackbar
      // fades. The password lives only in the operator's memory at this point
      // — the backend doesn't return it — so this is the only chance to copy
      // it for the SMS / phone-call handoff to the new owner.
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
      _showSnack(l10n.superAdminApproveSuccess(approved.username), isError: false);
    } else if (result.status == SuperAdminOpStatus.notFound) {
      _showSnack(result.message ?? l10n.superAdminApproveFailed, isError: true);
      _refreshRequests(); // Stale list — pull fresh data.
    } else if (result.status == SuperAdminOpStatus.validation) {
      _showSnack(result.message ?? l10n.superAdminApproveFailed, isError: true);
    } else if (result.status == SuperAdminOpStatus.unauthorized) {
      // JWT expired or SuperAdmin role revoked — kick back to login.
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } else {
      _showSnack(l10n.superAdminApproveFailed, isError: true);
    }
  }

  Future<void> _onReject(RegistrationRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => RejectRequestDialog(request: request),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    final result = await _service.reject(requestId: request.id, reason: reason);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (result.status == SuperAdminOpStatus.success) {
      _showSnack(l10n.superAdminRejectSuccess, isError: false);
      _refreshRequests();
    } else if (result.status == SuperAdminOpStatus.validation) {
      _showSnack(result.message ?? l10n.superAdminRejectFailed, isError: true);
    } else {
      _showSnack(l10n.superAdminRejectFailed, isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
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

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!AppConfig.hasSuperAdminConsole) {
      // Operator built the app without the console segment; calling the
      // backend would 404. Show a clear "misconfigured" screen instead of
      // a useless empty state.
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
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.superAdminConsoleTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.superAdminTabRequests),
            Tab(text: l10n.superAdminTabOwners),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
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
            onRefresh: _refreshOwners,
          ),
        ],
      ),
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
    if (error != null) {
      return _ErrorState(error: error!, onRetry: onRefresh);
    }
    final list = items ?? const <RegistrationRequest>[];
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(l10n.superAdminNoPendingRequests)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final req = list[index];
          return _RequestCard(
            request: req,
            onApprove: () => onApprove(req),
            onReject: () => onReject(req),
          );
        },
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.fullName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatDate(request.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  request.phone,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.superAdminReject),
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.superAdminApprove),
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnersTab extends StatelessWidget {
  const _OwnersTab({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRefresh,
  });
  final bool loading;
  final String? error;
  final List<OwnerSummary>? items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _ErrorState(error: error!, onRetry: onRefresh);
    final list = items ?? const <OwnerSummary>[];
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(l10n.superAdminNoActiveOwners)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final owner = list[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  owner.fullName.isNotEmpty
                      ? owner.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary),
                ),
              ),
              title: Text(owner.fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${owner.username}',
                      style:
                          const TextStyle(color: AppTheme.textSecondary)),
                  if (owner.marketName != null)
                    Text(owner.marketName!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  if (owner.phone != null)
                    Text(owner.phone!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
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
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
