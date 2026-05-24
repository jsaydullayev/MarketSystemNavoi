// Dashboard screen — owner / admin / seller home, redesigned to the
// new design system (see lib/design/*). Drawer navigation, role gating,
// theme toggle, language switcher, and logout are preserved from the
// previous implementation; only the body has been rebuilt to match the
// HTML demo (#page-owner-dash and #page-staff-dash in design-demo).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/network_wrapper.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/notification_service.dart';
import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../profile/screens/profile_screen.dart';
import 'dashboard_drawer.dart';
import 'dashboard_widgets.dart';
import 'owner_dashboard_body.dart';
import 'seller_dashboard_body.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardSummary>? _summaryFuture;
  Future<SellerDashboardSummary>? _sellerSummaryFuture;
  Future<int>? _unreadFuture;

  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = (auth.user?['role'] ?? 'Seller') as String;
    if (role == 'Owner') {
      _summaryFuture = DashboardService(authProvider: auth).loadOwnerSummary();
    } else if (role == 'Seller') {
      _sellerSummaryFuture =
          DashboardService(authProvider: auth).loadSellerSummary();
    }
    if (role == 'Owner' || role == 'Admin') {
      _unreadFuture =
          NotificationService(authProvider: auth).loadUnreadCount();
    }
  }

  Future<void> _refresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = (auth.user?['role'] ?? 'Seller') as String;
    setState(() {
      if (role == 'Owner') {
        _summaryFuture =
            DashboardService(authProvider: auth).loadOwnerSummary();
      } else if (role == 'Seller') {
        _sellerSummaryFuture =
            DashboardService(authProvider: auth).loadSellerSummary();
      }
      if (role == 'Owner' || role == 'Admin') {
        _unreadFuture =
            NotificationService(authProvider: auth).loadUnreadCount();
      }
    });
    // D1 — wait for all fetches to finish but DO NOT collapse their
    // results into safe empty values. Each future stays in state with
    // its original error so the child FutureBuilders can show
    // ErrorRetryView / _RetryBanner. The .catchError below produces
    // throwaway Futures used only to let the RefreshIndicator's
    // .onRefresh contract complete cleanly without an uncaught error.
    try {
      await Future.wait([
        if (_summaryFuture case final f?) f.catchError((_) => const DashboardSummary()),
        if (_sellerSummaryFuture case final f?) f.catchError((_) => const SellerDashboardSummary()),
        if (_unreadFuture case final f?) f.catchError((_) => 0),
      ]);
    } catch (_) {
      // already surfaced by the per-future builders
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final role = (user?['role'] ?? 'Seller') as String;
    final l10n = AppLocalizations.of(context)!;

    // D2 — wrap with NetworkWrapper so a fresh dashboard on a dropped
    // connection renders the localized no-internet panel (instead of
    // a half-empty summary). Reconnect → onRetry re-runs the futures.
    return NetworkWrapper(
      onRetry: _refresh,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        drawer: DashboardDrawer(user: user, role: role, l10n: l10n),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.menu_rounded, color: context.colors.text),
            ),
          ),
          title: Text(
            'STROTECH',
            style: AppTextStyles.titleMedium()
                .copyWith(letterSpacing: 2, color: context.colors.text),
          ),
        ),
        body: RefreshIndicator(
          color: context.colors.brand,
          onRefresh: _refresh,
          child: _DashboardBody(
            user: user,
            role: role,
            summaryFuture: _summaryFuture,
            sellerSummaryFuture: _sellerSummaryFuture,
            unreadFuture: _unreadFuture,
          ),
        ),
      ),
    );
  }
}

// Role-switcher: greeting card + owner or seller/admin body.
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.user,
    required this.role,
    this.summaryFuture,
    this.sellerSummaryFuture,
    this.unreadFuture,
  });

  final dynamic user;
  final String role;
  final Future<DashboardSummary>? summaryFuture;
  final Future<SellerDashboardSummary>? sellerSummaryFuture;
  final Future<int>? unreadFuture;

  String _fullName(BuildContext context) {
    final raw = user?['fullName'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return AppLocalizations.of(context)!.defaultUserName;
  }

  String _dateLabel(BuildContext context) {
    const monthsUz = [
      'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
      'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
    ];
    const monthsRu = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    final code = Localizations.localeOf(context).languageCode;
    final months = code == 'ru' ? monthsRu : monthsUz;
    final now = DateTime.now();
    final sep = code == 'ru' ? ' ' : '-';
    return '${now.day}$sep${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName(context);
    final date = _dateLabel(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<int>(
              future: unreadFuture,
              builder: (context, snapshot) {
                final unread = snapshot.data ?? 0;
                return GreetingCard(
                  fullName: name,
                  role: role,
                  dateLabel: date,
                  hasNotification: unread > 0,
                  unreadNotifications: unread,
                  profileImage: user?['profileImage'] as String?,
                  onNotificationTap: (role == 'Owner' || role == 'Admin')
                      ? () => Navigator.pushNamed(
                            context, AppRoutes.notifications)
                      : null,
                  onSettingsTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            if (role == 'Owner')
              OwnerDashboardBody(summaryFuture: summaryFuture)
            else
              SellerDashboardBody(
                  role: role, summaryFuture: sellerSummaryFuture),
          ],
        ),
      ),
    );
  }
}

