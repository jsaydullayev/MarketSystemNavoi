// Dashboard screen — owner / admin / seller home, redesigned to the
// new design system (see lib/design/*). Drawer navigation, role gating,
// theme toggle, language switcher, and logout are preserved from the
// previous implementation; only the body has been rebuilt to match the
// HTML demo (#page-owner-dash and #page-staff-dash in design-demo).

import 'dart:convert' show base64Decode;
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
  // Owner data load. We hold the [Future] in state so a pull-to-refresh can
  // replace it and the [FutureBuilder] in [_OwnerBody] rebuilds cleanly.
  // For non-Owner roles this stays null and we never touch the Owner-only
  // endpoints (profit-summary, etc.).
  Future<DashboardSummary>? _summaryFuture;
  // Seller data load — own performance + own drafts. Held in state for the
  // same pull-to-refresh pattern. Null for Owner/Admin.
  Future<SellerDashboardSummary>? _sellerSummaryFuture;
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
    } else if (role == 'Seller') {
      _sellerSummaryFuture =
          DashboardService(authProvider: auth).loadSellerSummary();
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
      } else if (role == 'Seller') {
        _sellerSummaryFuture =
            DashboardService(authProvider: auth).loadSellerSummary();
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
      if (_sellerSummaryFuture != null)
        _sellerSummaryFuture!.catchError((_) => const SellerDashboardSummary()),
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
          sellerSummaryFuture: _sellerSummaryFuture,
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
    // Localised month names. The greeting card previously hardcoded Uzbek
    // month spellings ("yanvar", "fevral", ...) which leaked Uzbek date
    // strings into the Russian UI ("19-may" instead of "19 мая"). Picks
    // from the bundle based on the current locale code.
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
    // Uzbek style uses a hyphen ("19-may"); Russian style uses a space
    // ("19 мая") — preserves the convention each language reads naturally.
    final sep = code == 'ru' ? ' ' : '-';
    return '${now.day}$sep${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName(context);
    final date = _dateLabel(context);

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
                  // Profile image is stored on the user map as a base64 data
                  // URI (see ProfileImagePicker upload). GreetingCard handles
                  // both URL and base64 forms and falls back to the letter
                  // tile when null/empty.
                  profileImage: user?['profileImage'] as String?,
                  onNotificationTap: (role == 'Owner' || role == 'Admin')
                      ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.notifications,
                          )
                      : null,
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
              _SellerBody(role: role, summaryFuture: sellerSummaryFuture),
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
              // Header label (rendered uppercase by the card). Was
              // hardcoded to 'Bugungi sotuv' on the widget side; now
              // sourced from l10n so the Russian locale gets the
              // localised header too.
              label: l10n.todaysSale,
              // No deltaText: we don't yet have a yesterday-comparison
              // endpoint for daily revenue. Previously this was passed
              // l10n.todaysSale, producing a misleading green "↑ Bugungi
              // sotuv" row directly below the header that read the same.
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
            // Alert preview — at most 2–3 cards rendered, ordered by urgency:
            //   1. Overdue debts (danger)   — to'lov muddati o'tgan
            //   2. Active debts that aren't overdue yet (warning)
            //   3. Low-stock products (warning)
            // When all three buckets are empty we show a single success
            // card (green tick) so the slot doesn't disappear and shrink
            // the layout. Tapping any card lands on the relevant feature
            // screen so the owner can act immediately.
            ..._buildAlertPreviewCards(context, summary, l10n),
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

  /// Dashboard alert-preview row builder. Returns an ordered list of widgets
  /// (cards interleaved with spacers) so the caller can splat them with `...`
  /// into the surrounding Column. Empty buckets are skipped entirely, and
  /// when every bucket is empty we fall through to a single success card —
  /// the slot never collapses, the section header always has something
  /// under it.
  static List<Widget> _buildAlertPreviewCards(
    BuildContext context,
    DashboardSummary summary,
    AppLocalizations l10n,
  ) {
    final cards = <Widget>[];

    // 1) Overdue payments — most urgent. Heuristic for "due today" until
    //    the Debt entity gains a real DueDate field.
    if (summary.overdueDebtsCount > 0) {
      cards.add(AlertCard(
        emoji: '⚠️',
        title: l10n.alertPreviewOverdueDebts(summary.overdueDebtsCount),
        description: l10n.alertPreviewOverdueDebtsDesc,
        tone: AlertTone.danger,
        onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
      ));
    }

    // 2) Active-but-not-yet-overdue debts. Subtract the overdue count so
    //    we don't double-report the same debt in two cards.
    final nonOverdueActive = summary.pendingDebtsCount - summary.overdueDebtsCount;
    if (nonOverdueActive > 0) {
      cards.add(AlertCard(
        emoji: '💸',
        title: l10n.alertPreviewActiveDebts(nonOverdueActive),
        description: l10n.alertPreviewActiveDebtsDesc(
          NumberFormatter.format(summary.pendingDebtsTotal),
        ),
        tone: AlertTone.warning,
        onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
      ));
    }

    // 3) Low-stock — least urgent of the three.
    if (summary.lowStockCount > 0) {
      cards.add(AlertCard(
        emoji: '📦',
        title: l10n.alertPreviewLowStock(summary.lowStockCount),
        description: l10n.alertPreviewLowStockDesc,
        tone: AlertTone.warning,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProductsScreen(isReadOnly: false),
          ),
        ),
      ));
    }

    if (cards.isEmpty) {
      return [
        AlertCard(
          emoji: '✅',
          title: l10n.alertPreviewEmpty,
          description: l10n.alertPreviewEmptyDesc,
          tone: AlertTone.success,
        ),
      ];
    }

    // Interleave spacers between cards (but not after the last one).
    final out = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      out.add(cards[i]);
      if (i != cards.length - 1) {
        out.add(const SizedBox(height: AppSpacing.md));
      }
    }
    return out;
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
    // pass the magnitude as a plain "5%" string and let the card add the
    // sign arrow + colour itself. Previously we baked the arrow into the
    // string which (combined with the card hardcoding its own "↑") rendered
    // a double-arrow ("↑ ↑ 5%") in the up case and an always-green arrow
    // in the down case. Falls back to blank when the previous week was
    // empty (division-by-zero would yield infinity) or the comparison
    // wasn't requested.
    final delta = summary.weeklyDeltaPercent;
    String footerDelta = '';
    bool deltaIsPositive = true;
    if (delta != null && !delta.isNaN && !delta.isInfinite) {
      deltaIsPositive = delta >= 0;
      footerDelta = '${delta.abs().toStringAsFixed(0)}%';
    }

    return ChartCard(
      title: l10n.thisWeekLabel,
      period: l10n.thisWeekLabel,
      bars: bars,
      footerValue: footerValue,
      footerDelta: footerDelta,
      deltaIsPositive: deltaIsPositive,
      // When neither the current nor previous week have any data, dim the
      // bars so the card reads as "no data yet" rather than "everything is
      // a flat tiny bar above 0".
      isEmpty: series.isEmpty || maxRev == 0,
    );
  }

  /// Top-3 sellers card. Prefers the new /Reports/top-products endpoint
  /// (period=today). Falls back to the legacy local aggregation when the
  /// endpoint returned nothing, so an older backend still shows data.
  ///
  /// The new endpoint transparently widens "today" → "week" when today has
  /// no sales (see ReportService.GetTopProductsAsync). We honour the echoed
  /// period in the panel label so users aren't confused by week-old products
  /// appearing under a "Bugun" header.
  static TopSellersCard _buildTopSellersCard(
    BuildContext context,
    DashboardSummary summary,
    AppLocalizations l10n,
  ) {
    final rows = summary.topProductRows;
    final periodLabel = summary.topProductsPeriod == 'week'
        ? l10n.thisWeek
        : l10n.todayLabel;
    if (rows.isNotEmpty) {
      return TopSellersCard(
        title: l10n.bestSellersTitle,
        period: periodLabel,
        entries: [
          for (final p in rows.take(3))
            TopSellerEntry(
              emoji: '🛒',
              name: p.name,
              countLabel:
                  '${NumberFormatter.formatQuantity(p.quantity)} ${l10n.unitPiece}',
            ),
        ],
      );
    }
    // Fallback to the legacy locally-aggregated list.
    final legacy = summary.topProducts;
    return TopSellersCard(
      title: l10n.bestSellersTitle,
      period: periodLabel,
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
                      '${NumberFormatter.formatQuantity(p.quantity)} ${l10n.unitPiece}',
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
            // Top product KPI — shows the *name* of the bestselling product
            // today (or the period the backend fell back to), not a count.
            // The previous "{distinct-product-count}" rendering was confusing:
            // a user looking at "5 · Top mahsulot" can't tell whether 5 is
            // a rank, a count, or a quantity. Pulling the name from
            // topProductRows.first makes the card immediately readable.
            KpiCard(
              emoji: '💎',
              value: summary.topProductRows.isNotEmpty
                  ? summary.topProductRows.first.name
                  : '—',
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
  const _SellerBody({required this.role, this.summaryFuture});

  final String role;
  // Seller summary future. Null for Admins — they don't get the personal
  // stats / draft card (they're typically not the one ringing up sales). The
  // Admin layout reuses this widget for the "Quick actions" + admin shortcuts
  // grid below.
  final Future<SellerDashboardSummary>? summaryFuture;

  /// Compact UZS formatter for the stats row: "1 200 000" → "1.2M",
  /// "42 500" → "42.5K", "950" → "950". Mirrors the Owner KPI compact
  /// helper — see _OwnerBody._compact.
  String _compactUzs(double v) {
    final n = v.abs();
    if (n >= 1000000) {
      final m = v / 1000000;
      // 12.4M → "12M" (drop decimal once magnitude is ≥10 so cards don't
      // get crowded), 1.5M → "1.5M".
      return '${m.toStringAsFixed(m.abs() >= 10 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final k = v / 1000;
      // Previously the K branch was `(v % 1000 == 0 ? 0 : 0)` — both
      // arms were 0, so "1500" rendered as "2K" instead of "1.5K".
      return '${k.toStringAsFixed(k.abs() >= 100 ? 0 : 1)}K';
    }
    return v.toStringAsFixed(0);
  }

  /// Pretty thousands-grouped UZS for the draft subtitle. We use a thin space
  /// (U+202F) so the rendering matches the rest of the app (e.g. "42 000").
  String _grouped(double v) {
    final n = v.toStringAsFixed(0);
    final buf = StringBuffer();
    final neg = n.startsWith('-');
    final digits = neg ? n.substring(1) : n;
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return neg ? '-${buf.toString()}' : buf.toString();
  }

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
        // Seller-only: pending draft + personal stats row, wired to
        // /Reports/my-performance + /Sales/my-drafts.
        if (!isAdmin) ...[
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<SellerDashboardSummary>(
            future: summaryFuture,
            builder: (context, snapshot) {
              final summary =
                  snapshot.data ?? const SellerDashboardSummary();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary.pendingDraft != null)
                    PendingSaleCard(
                      title: l10n.oneSaleInProgress,
                      subtitle: () {
                        final d = summary.pendingDraft!;
                        // "3 dona · 42 000 UZS"
                        return '${d.itemCount} ${l10n.unitPiece} · '
                            '${_grouped(d.totalAmount)} UZS';
                      }(),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.sales),
                    ),
                  if (summary.pendingDraft != null)
                    const SizedBox(height: AppSpacing.lg),
                  SellerStatsRow(
                    stats: [
                      SalesHeroStat(
                        value: '${summary.mySaleCount}',
                        label: l10n.todayLabel,
                      ),
                      SalesHeroStat(
                        value: _compactUzs(summary.myRevenue),
                        label: l10n.revenueLabel,
                      ),
                      SalesHeroStat(
                        value: '${summary.myShiftDurationHours} ${l10n.hour}',
                        label: l10n.shiftLabel,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
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
                // Big text: short noun ("Qaytarish"). Subtitle: action
                // description ("Sotuvni qaytarish"). Previously both were
                // refundLabel, so the card rendered the same string twice.
                value: l10n.refundLabel,
                label: l10n.refundActionDesc,
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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.surface,
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
    final rawName = user?['fullName'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName
        : l10n.defaultUserName;
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
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: _buildAvatar(user?['profileImage'] as String?, initial),
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

  /// Render the user's avatar: profile image when set + decodable,
  /// otherwise the coloured first-letter circle. Mirrors GreetingCard's
  /// rendering logic — profileImage may be a URL, a base64 data URI, or a
  /// raw base64 blob; anything else falls back to the letter.
  Widget _buildAvatar(String? img, String initial) {
    final fallback = _fallback(initial);
    if (img == null || img.isEmpty) return fallback;

    Widget? imgWidget;
    if (img.startsWith('http')) {
      imgWidget = Image.network(
        img,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      );
    } else if (img.startsWith('data:image') || img.length > 100) {
      try {
        final b64 = img.contains(',') ? img.split(',').last : img;
        imgWidget = Image.memory(
          base64Decode(b64),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        imgWidget = null;
      }
    }
    return imgWidget ?? fallback;
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
