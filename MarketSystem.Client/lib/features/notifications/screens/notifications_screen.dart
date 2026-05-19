// Owner/Admin notifications screen.
//
// Bell tap on the dashboard lands here. Renders three sections fed by
// NotificationService.loadAlerts():
//
//   • Kam qolgan tovarlar       (warning tone)
//   • Qarzga yozilgan savdolar  (warning tone — bugun / yangi)
//   • Qarzdor mijozlar — to'lov vaqti keldi (danger tone — kechikkan)
//
// All three sources are existing read-only endpoints; this screen is a pure
// presentation layer. Pull-to-refresh re-fetches the feed. Tapping a card
// navigates to the relevant detail screen (debts / products) so the owner
// can act on the alert.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_app_bar.dart';
import '../../../data/services/notification_service.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/dashboard_widgets.dart' show AlertCard, AlertTone, SectionHeader;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<AlertFeed> _feedFuture;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _feedFuture = _load();
  }

  Future<AlertFeed> _load() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return NotificationService(authProvider: auth).loadAlerts();
  }

  Future<void> _refresh() async {
    setState(() {
      _feedFuture = _load();
    });
    await _feedFuture.catchError((_) => const AlertFeed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: CommonAppBar(title: l10n.notificationsTitle),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _refresh,
        child: FutureBuilder<AlertFeed>(
          future: _feedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              );
            }
            final feed = snapshot.data ?? const AlertFeed();
            if (feed.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const SizedBox(height: 80),
                  _EmptyState(l10n: l10n),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                if (feed.overdueDebts.isNotEmpty) ...[
                  SectionHeader(title: l10n.alertsOverdueTitle),
                  const SizedBox(height: AppSpacing.md),
                  ..._buildSection(
                    context,
                    items: feed.overdueDebts,
                    tone: AlertTone.danger,
                    emoji: '⚠️',
                    onTap: (item) =>
                        Navigator.pushNamed(context, AppRoutes.debts),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (feed.lowStock.isNotEmpty) ...[
                  SectionHeader(title: l10n.alertsLowStockTitle),
                  const SizedBox(height: AppSpacing.md),
                  ..._buildSection(
                    context,
                    items: feed.lowStock,
                    tone: AlertTone.warning,
                    emoji: '📦',
                    onTap: (item) =>
                        Navigator.pushNamed(context, AppRoutes.products),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (feed.recentDebts.isNotEmpty) ...[
                  SectionHeader(title: l10n.alertsRecentDebtTitle),
                  const SizedBox(height: AppSpacing.md),
                  ..._buildSection(
                    context,
                    items: feed.recentDebts,
                    tone: AlertTone.warning,
                    emoji: '💳',
                    onTap: (item) =>
                        Navigator.pushNamed(context, AppRoutes.debts),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Stamp the same card style on every row of a section so the visual
  /// language stays consistent — only the title / description / on-tap
  /// target varies between buckets.
  List<Widget> _buildSection(
    BuildContext context, {
    required List<AlertItem> items,
    required AlertTone tone,
    required String emoji,
    required void Function(AlertItem item) onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return [
      for (final item in items) ...[
        AlertCard(
          emoji: emoji,
          title: item.title.isEmpty ? l10n.fallbackCustomerName : item.title,
          description: _buildDescription(l10n, item),
          tone: tone,
          onTap: () => onTap(item),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  /// Builds the localised one-line description for an alert item from its
  /// raw fields. The service intentionally stores raw numbers + days so
  /// this can re-format with the active locale (previously the service
  /// hardcoded Uzbek phrases like "Bugun · …" which leaked into the
  /// Russian UI as in screenshot 2026-05-19).
  String _buildDescription(AppLocalizations l10n, AlertItem item) {
    switch (item.category) {
      case AlertCategory.lowStock:
        final qty = _fmtNum(item.quantity ?? 0);
        final unit = (item.unit ?? '').trim();
        final threshold = item.threshold ?? 0;
        if (threshold > 0) {
          return l10n.alertDescLowStock(
            qty,
            unit,
            _fmtNum(threshold),
          );
        }
        return l10n.alertDescLowStockNoMin(qty, unit);
      case AlertCategory.recentDebt:
        return l10n.alertDescRecent(_fmtUzs(item.amount ?? 0));
      case AlertCategory.overduePayment:
        return l10n.alertDescOverdue(
          item.ageDays ?? 0,
          _fmtUzs(item.amount ?? 0),
        );
    }
  }

  /// "1500" → "1500" (whole) or "1.5" (fractional). Locale-neutral.
  String _fmtNum(num v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  /// Group thousands with a space ("115500" → "115 500"). UZS rendering
  /// — same convention used elsewhere in the app (e.g. NumberFormatter).
  String _fmtUzs(num v) {
    final n = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write(' ');
      buf.write(n[i]);
    }
    return buf.toString();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            alignment: Alignment.center,
            child: const Text('✅', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.notificationsEmptyTitle,
            style: AppTextStyles.titleMedium()
                .copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.notificationsEmptyDescription,
            style: AppTextStyles.bodySmall()
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
