// Dashboard screen — owner / admin / seller home, redesigned to the
// new design system (see lib/design/*). Drawer navigation, role gating,
// theme toggle, language switcher, and logout are preserved from the
// previous implementation; only the body has been rebuilt to match the
// HTML demo (#page-owner-dash and #page-staff-dash in design-demo).

import 'dart:math' show max;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/notification_service.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../categories/screens/category_management_screen.dart';
import '../daily_sales/screens/daily_sales_screen.dart';
import '../products/presentation/screens/products_screen.dart';
import '../profile/screens/profile_screen.dart';
import 'dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Owner-only data load. We hold the [Future] in state so a pull-to-refresh
  // can replace it and the [FutureBuilder] in [_OwnerBody] rebuilds cleanly.
  // For non-Owner roles these stay null and we never touch the services.
  Future<DashboardSummary>? _summaryFuture;
  Future<int>? _unreadFuture;

  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial fetch — runs once, after AuthProvider is available in context.
    if (_initialised) return;
    _initialised = true;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = (auth.user?['role'] ?? 'Seller') as String;
    if (role == 'Owner') {
      _summaryFuture = DashboardService(authProvider: auth).loadOwnerSummary();
    }
    // Bell badge is useful for Owner + Admin (both manage low-stock / debts).
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
      }
      if (role == 'Owner' || role == 'Admin') {
        _unreadFuture =
            NotificationService(authProvider: auth).loadUnreadCount();
      }
    });
    // Await whichever futures we actually scheduled so RefreshIndicator's
    // spinner stays visible until the data lands.
    await Future.wait([
      if (_summaryFuture != null) _summaryFuture!.catchError((_) =>
          const DashboardSummary()),
      if (_unreadFuture != null) _unreadFuture!.catchError((_) => 0),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final role = (user?['role'] ?? 'Seller') as String;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _DashboardDrawer(user: user, role: role, l10n: l10n),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: AppColors.text),
          ),
        ),
        title: Text(
          'STROTECH',
          style: AppTextStyles.titleMedium()
              .copyWith(letterSpacing: 2, color: AppColors.text),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _refresh,
        child: _DashboardBody(
          user: user,
          role: role,
          summaryFuture: _summaryFuture,
          unreadFuture: _unreadFuture,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — switches layout by role: Owner shows the analytics dashboard,
// Seller/Admin show the action-focused layout.
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.user,
    required this.role,
    this.summaryFuture,
    this.unreadFuture,
  });

  final dynamic user;
  final String role;
  final Future<DashboardSummary>? summaryFuture;
  final Future<int>? unreadFuture;

  String _fullName(BuildContext context) {
    final raw = user?['fullName'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return AppLocalizations.of(context)!.defaultUserName;
  }

  String _dateLabel() {
    const months = [
      'yanvar',
      'fevral',
      'mart',
      'aprel',
      'may',
      'iyun',
      'iyul',
      'avgust',
      'sentabr',
      'oktabr',
      'noyabr',
      'dekabr',
    ];
    final now = DateTime.now();
    return '${now.day}-${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName(context);
    final date = _dateLabel();

    // Greeting bell badge — true when there's at least one "thing to look at"
    // (low-stock, today's debt, etc.). Reflects unreadFuture once it resolves;
    // before then we fall back to false rather than guessing red.
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
                final unread = (snapshot.data ?? 0);
                return GreetingCard(
                  fullName: name,
                  role: role,
                  dateLabel: date,
                  hasNotification: unread > 0,
                  unreadNotifications: unread,
                  onSettingsTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            if (role == 'Owner')
              _OwnerBody(summaryFuture: summaryFuture)
            else
              _SellerBody(role: role),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Owner layout — hero card + KPI grid + alerts + chart + top sellers.
// ---------------------------------------------------------------------------

class _OwnerBody extends StatelessWidget {
  const _OwnerBody({this.summaryFuture});

  /// Future supplied by [_DashboardScreenState]. May be null briefly while
  /// the state is initialising — in that case we render the loading skeleton
  /// rather than crash.
  final Future<DashboardSummary>? summaryFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<DashboardSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            summaryFuture == null) {
          return const _OwnerBodySkeleton();
        }
        // Connection done. Use whatever we got; the service itself swallows
        // per-source errors and fills zeros, so a hard error here is rare.
        // If we do see one (network down before any source ran), show a
        // small retry banner above an empty body.
        final summary = snapshot.data ?? const DashboardSummary();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.hasError)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: _RetryBanner(),
              ),
            SalesHeroCard(
              amount: NumberFormatter.format(summary.todayRevenue),
              deltaText: l10n.todaysSale,
              stats: [
                SalesHeroStat(
                  value: '${summary.todayCheckCount}',
                  label: l10n.checkLabel,
                ),
                SalesHeroStat(
                  value: '${summary.todayCustomerCount}',
                  label: l10n.mijozLabel,
                ),
                SalesHeroStat(
                  value: _compact(summary.todayProfit),
                  label: l10n.profitLabel,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l10n.statisticsSectionLabel,
              actionLabel: l10n.viewAll,
              onAction: () => Navigator.pushNamed(context, AppRoutes.reports),
            ),
            const SizedBox(height: AppSpacing.md),
            _KpiGrid(summary: summary),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.alertsSectionLabel),
            const SizedBox(height: AppSpacing.md),
            if (summary.pendingDebtsCount > 0)
              AlertCard(
                emoji: '💸',
                title:
                    '${summary.pendingDebtsCount} ta faol qarz mavjud',
                description:
                    'Jami: ${NumberFormatter.format(summary.pendingDebtsTotal)} UZS',
                tone: AlertTone.danger,
                onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
              ),
            if (summary.pendingDebtsCount > 0 && summary.lowStockCount > 0)
              const SizedBox(height: AppSpacing.md),
            if (summary.lowStockCount > 0)
              AlertCard(
                emoji: '📦',
                title:
                    '${summary.lowStockCount} ta mahsulot tugab qoldi',
                description: "Omborni to'ldirish kerak",
                tone: AlertTone.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductsScreen(isReadOnly: false),
                  ),
                ),
              ),
            if (summary.pendingDebtsCount == 0 && summary.lowStockCount == 0)
              const AlertCard(
                emoji: '✅',
                title: "Hech qanday ogohlantirish yo'q",
                description: 'Hammasi joyida',
                tone: AlertTone.warning,
              ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l10n.analysisSectionLabel,
              actionLabel: l10n.reportsActionLabel,
              onAction: () => Navigator.pushNamed(context, AppRoutes.reports),
            ),
            const SizedBox(height: AppSpacing.md),
            // ChartCard — bars come from /Reports/weekly-series (last 7 days,
            // oldest → newest). Heights normalised to [0..1] against the
            // window's max revenue so the tallest day reaches 100%.
            _buildChartCard(context, summary, l10n),
            const SizedBox(height: AppSpacing.lg),
            // Top-sellers list — uses /Reports/top-products?period=today
            // (preferred) and falls back to the legacy daily-items aggregate
            // when the new endpoint returned nothing (e.g. older backend).
            _buildTopSellersCard(context, summary, l10n),
            const SizedBox(height: AppSpacing.xl2),
          ],
        );
      },
    );
  }

  /// Compact representation for the small "Foyda" stat (e.g. 450 000 → "450K",
  /// 12 400 000 → "12.4M"). Falls back to plain space-separated digits for
  /// small numbers so a 90 000 UZS profit doesn't render as "0.1M".
  static String _compact(double value) {
    if (value.abs() >= 1000000) {
      final m = value / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (value.abs() >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(k >= 100 ? 0 : 1)}K';
    }
    return NumberFormatter.format(value);
  }

  /// Bar chart for the last 7 days, fed by [DashboardSummary.weeklySeries].
  /// Bars are scaled to the window's max revenue (so the tallest day fills
  /// the card) and the footer shows the running total. If the endpoint
  /// returned an empty list we still render the card with a "—" footer
  /// rather than hiding it — keeps the layout stable on retry.
  static ChartCard _buildChartCard(
    BuildContext context,
    DashboardSummary summary,
    AppLocalizations l10n,
  ) {
    final series = summary.weeklySeries;
    final maxRev = series.fold<double>(0, (m, p) => max(m, p.revenue));
    final bars = series.isEmpty
        // Tiny placeholder bars so the empty card doesn't look broken.
        ? const <double>[0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05]
        : series
            .map((p) => maxRev == 0 ? 0.0 : p.revenue / maxRev)
            .toList();
    final totalWeek =
        series.fold<double>(0, (sum, p) => sum + p.revenue);
    final footerValue = totalWeek > 0
        ? '${NumberFormatter.format(totalWeek)} UZS'
        : '— UZS';

    // Week-over-week delta — sourced from /weekly-series?compare=true. We
    // render the sign + integer percent + a localized "vs last week" hint.
    // Falls back to blank when the previous week was empty (division-by-zero
    // would otherwise yield infinity) or the comparison wasn't requested.
    final delta = summary.weeklyDeltaPercent;
    String footerDelta;
    if (delta == null || delta.isNaN || delta.isInfinite) {
      footerDelta = '';
    } else {
      final sign = delta >= 0 ? '↑' : '↓';
      footerDelta = '$sign ${delta.abs().toStringAsFixed(0)}%';
    }

    return ChartCard(
      title: l10n.thisWeekLabel,
      period: l10n.thisWeekLabel,
      bars: bars,
      footerValue: footerValue,
      footerDelta: footerDelta,
    );
  }

  /// Top-3 sellers card. Prefers the new /Reports/top-products endpoint
  /// (period=today). Falls back to the legacy local aggregation when the
  /// endpoint returned nothing, so an older backend still shows data.
  static TopSellersCard _buildTopSellersCard(
    BuildContext context,
    DashboardSummary summary,
    AppLocalizations l10n,
  ) {
    final rows = summary.topProductRows;
    if (rows.isNotEmpty) {
      return TopSellersCard(
        title: l10n.bestSellersTitle,
        period: l10n.todayLabel,
        entries: [
          for (final p in rows.take(3))
            TopSellerEntry(
              emoji: '🛒',
              name: p.name,
              countLabel:
                  '${NumberFormatter.formatQuantity(p.quantity)} dona',
            ),
        ],
      );
    }
    // Fallback to the legacy locally-aggregated list.
    final legacy = summary.topProducts;
    return TopSellersCard(
      title: l10n.bestSellersTitle,
      period: l10n.todayLabel,
      entries: legacy.isEmpty
          ? [
              TopSellerEntry(
                emoji: '🛒',
                name: l10n.noProducts,
                countLabel: '—',
              ),
            ]
          : [
              for (final p in legacy)
                TopSellerEntry(
                  emoji: '🛒',
                  name: p.name,
                  countLabel:
                      '${NumberFormatter.formatQuantity(p.quantity)} dona',
                ),
            ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 700;
        final crossCount = isWide ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: [
            KpiCard(
              emoji: '💰',
              value: _OwnerBody._compact(summary.weekProfit),
              label: l10n.weekProfit,
              tone: KpiTone.green,
            ),
            KpiCard(
              emoji: '📊',
              value: _OwnerBody._compact(summary.monthRevenue),
              label: l10n.monthRevenue,
              tone: KpiTone.purple,
            ),
            KpiCard(
              emoji: '👥',
              value: '${summary.customerCount}',
              label: l10n.customers,
              tone: KpiTone.blue,
            ),
            KpiCard(
              emoji: '💎',
              value: '${summary.topProductCount}',
              label: l10n.topProduct,
              tone: KpiTone.orange,
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton + retry banner — local to the Owner body.
// ---------------------------------------------------------------------------

class _OwnerBodySkeleton extends StatelessWidget {
  const _OwnerBodySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SkeletonBox(height: 160, radius: AppRadius.xl),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 700;
            final crossCount = isWide ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossCount,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: List.generate(
                  4, (_) => const _SkeletonBox(height: 100)),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SkeletonBox(height: 64),
        const SizedBox(height: AppSpacing.md),
        const _SkeletonBox(height: 64),
        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.height = 80, this.radius = AppRadius.lg});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
    );
  }
}

class _RetryBanner extends StatelessWidget {
  const _RetryBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: AppColors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.pullToRefresh,
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seller / Admin layout — big CTA, pending sale, quick stats, admin shortcuts.
// ---------------------------------------------------------------------------

class _SellerBody extends StatelessWidget {
  const _SellerBody({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = role == 'Admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellerHeroCta(
          emoji: '🛒',
          title: l10n.newSale,
          subtitle: l10n.tapToSelectProduct,
          onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
        ),
        const SizedBox(height: AppSpacing.lg),
        PendingSaleCard(
          title: l10n.oneSaleInProgress,
          subtitle: 'Chek #1247 · 3 dona · 42 000 UZS',
          onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
        ),
        const SizedBox(height: AppSpacing.lg),
        SellerStatsRow(
          stats: [
            SalesHeroStat(value: '12', label: l10n.todayLabel),
            SalesHeroStat(value: '850K', label: l10n.revenueLabel),
            SalesHeroStat(value: '6 ${l10n.hour}', label: l10n.shiftLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.quickActions),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                emoji: '💸',
                value: l10n.debt,
                label: l10n.debtPayments,
                tone: KpiTone.orange,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.debts),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                emoji: '↩️',
                value: l10n.refundLabel,
                label: l10n.refundLabel,
                tone: KpiTone.blue,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.sales),
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.adminSectionLabel),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  emoji: '🧾',
                  value: l10n.reportLabel,
                  label: l10n.reportsActionLabel,
                  tone: KpiTone.green,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.reports),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: KpiCard(
                  emoji: '💼',
                  value: l10n.cashRegisterShort,
                  label: l10n.cashRegister,
                  tone: KpiTone.purple,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.cashRegister),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer — preserves the previous menu items, theme toggle, language
// switcher, and logout, but uses the new design tokens for surfaces / type.
// ---------------------------------------------------------------------------

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.user,
    required this.role,
    required this.l10n,
  });

  final dynamic user;
  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 900 ? 320.0 : 280.0;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    return Drawer(
      width: width,
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(user: user, role: role, l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                children: [
                  ..._menuTiles(context, role),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsTile(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: isDark ? l10n.lightMode : l10n.darkMode,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeThumbColor: AppColors.brand,
                      onChanged: (_) {
                        if (isDark) {
                          AdaptiveTheme.of(context).setLight();
                        } else {
                          AdaptiveTheme.of(context).setDark();
                        }
                      },
                    ),
                    onTap: () {
                      if (isDark) {
                        AdaptiveTheme.of(context).setLight();
                      } else {
                        AdaptiveTheme.of(context).setDark();
                      }
                    },
                  ),
                  Consumer<LocaleProvider>(
                    builder: (context, lp, _) => _SettingsTile(
                      icon: Icons.translate_rounded,
                      label: lp.locale.languageCode == 'uz'
                          ? "O'zbekcha"
                          : 'Русский',
                      onTap: () => _showLanguageDialog(context, lp),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                color: AppColors.border,
                indent: AppSpacing.xl,
                endIndent: AppSpacing.xl,
                height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: _SettingsTile(
                icon: Icons.logout_rounded,
                label: l10n.logout,
                tint: AppColors.danger,
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the list of menu tiles, gated by role.
  List<Widget> _menuTiles(BuildContext context, String role) {
    final items = <_DrawerItem>[
      _DrawerItem(
        icon: Icons.inventory_2_rounded,
        label: l10n.products,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsScreen(isReadOnly: role == 'Seller'),
          ),
        ),
      ),
      _DrawerItem(
        icon: Icons.grid_view_rounded,
        label: l10n.categories,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
        ),
      ),
      _DrawerItem(
        icon: Icons.shopping_bag_rounded,
        label: l10n.sales,
        onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
      ),
      _DrawerItem(
        icon: Icons.receipt_long_rounded,
        label: l10n.dailySales,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailySalesScreen()),
        ),
      ),
      _DrawerItem(
        icon: Icons.people_alt_rounded,
        label: l10n.customers,
        onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
      ),
      _DrawerItem(
        icon: Icons.add_business_rounded,
        label: l10n.zakup,
        onTap: () => Navigator.pushNamed(context, AppRoutes.zakup),
      ),
    ];

    if (role == 'Admin' || role == 'Owner') {
      items.addAll([
        _DrawerItem(
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.cashRegister,
          onTap: () => Navigator.pushNamed(context, AppRoutes.cashRegister),
        ),
        _DrawerItem(
          icon: Icons.bar_chart_rounded,
          label: l10n.reports,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
        _DrawerItem(
          icon: Icons.admin_panel_settings,
          label: l10n.users,
          onTap: () => Navigator.pushNamed(context, AppRoutes.users),
        ),
        _DrawerItem(
          icon: Icons.monetization_on_rounded,
          label: l10n.debts,
          onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
        ),
      ]);
    }

    return [
      for (final it in items)
        _SettingsTile(
          icon: it.icon,
          label: it.label,
          onTap: () {
            Navigator.pop(context); // close drawer first
            it.onTap();
          },
        ),
    ];
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider lp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            const Icon(Icons.translate_rounded, color: AppColors.brand),
            const SizedBox(width: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: AppTextStyles.titleMedium(),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(ctx, lp, "O'zbekcha", 'uz', '🇺🇿'),
            _languageOption(ctx, lp, 'Русский', 'ru', '🇷🇺'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext ctx,
    LocaleProvider lp,
    String title,
    String code,
    String flag,
  ) {
    final isSelected = lp.locale.languageCode == code;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        lp.setLocale(code);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  isSelected ? AppColors.brand : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.lg),
            Text(title, style: AppTextStyles.bodyLarge()),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer pieces.
// ---------------------------------------------------------------------------

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.user,
    required this.role,
    required this.l10n,
  });

  final dynamic user;
  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final name = (user?['fullName'] as String?) ??
        (l10n.localeName == 'uz' ? 'Foydalanuvchi' : 'Пользователь');
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: user?['profileImage'] != null
                  ? Image.network(
                      user!['profileImage'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(initial),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _fallback(initial),
                    )
                  : _fallback(initial),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.labelLarge().copyWith(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_note_rounded,
                color: AppColors.brand, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _fallback(String initial) => Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: AppTextStyles.titleMedium()
              .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final color = tint ?? (isDark ? Colors.white : AppColors.text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium()
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
