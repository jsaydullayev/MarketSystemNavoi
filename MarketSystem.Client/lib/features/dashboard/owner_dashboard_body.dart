import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/services/dashboard_service.dart';
import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../products/presentation/screens/products_screen.dart';
import 'dashboard_widgets.dart';

class OwnerDashboardBody extends StatelessWidget {
  const OwnerDashboardBody({super.key, this.summaryFuture});

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
              label: l10n.todaysSale,
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
                  value: compact(summary.todayProfit),
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
            ..._buildAlertPreviewCards(context, summary, l10n),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l10n.analysisSectionLabel,
              actionLabel: l10n.reportsActionLabel,
              onAction: () => Navigator.pushNamed(context, AppRoutes.reports),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildChartCard(context, summary, l10n),
            const SizedBox(height: AppSpacing.lg),
            _buildTopSellersCard(context, summary, l10n),
            const SizedBox(height: AppSpacing.xl2),
          ],
        );
      },
    );
  }

  /// Compact representation for KPI values (e.g. 450 000 → "450K", 12.4M).
  static String compact(double value) {
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

  static List<Widget> _buildAlertPreviewCards(
    BuildContext context,
    DashboardSummary summary,
    AppLocalizations l10n,
  ) {
    final cards = <Widget>[];

    if (summary.overdueDebtsCount > 0) {
      cards.add(
        AlertCard(
          emoji: '⚠️',
          title: l10n.alertPreviewOverdueDebts(summary.overdueDebtsCount),
          description: l10n.alertPreviewOverdueDebtsDesc,
          tone: AlertTone.danger,
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
        ),
      );
    }

    final nonOverdueActive =
        summary.pendingDebtsCount - summary.overdueDebtsCount;
    if (nonOverdueActive > 0) {
      cards.add(
        AlertCard(
          emoji: '💸',
          title: l10n.alertPreviewActiveDebts(nonOverdueActive),
          description: l10n.alertPreviewActiveDebtsDesc(
            NumberFormatter.format(summary.pendingDebtsTotal),
          ),
          tone: AlertTone.warning,
          onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
        ),
      );
    }

    if (summary.lowStockCount > 0) {
      cards.add(
        AlertCard(
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
        ),
      );
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

    final out = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      out.add(cards[i]);
      if (i != cards.length - 1) {
        out.add(const SizedBox(height: AppSpacing.md));
      }
    }
    return out;
  }

  static ChartCard _buildChartCard(
    BuildContext context,
    DashboardSummary summary,
    AppLocalizations l10n,
  ) {
    final series = summary.weeklySeries;
    final maxRev = series.fold<double>(0, (m, p) => max(m, p.revenue));
    final bars = series.isEmpty
        ? const <double>[0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05]
        : series.map((p) => maxRev == 0 ? 0.0 : p.revenue / maxRev).toList();
    final totalWeek = series.fold<double>(0, (sum, p) => sum + p.revenue);
    final footerValue = totalWeek > 0
        ? '${NumberFormatter.format(totalWeek)} UZS'
        : '— UZS';

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
      deltaCaption: footerDelta.isEmpty ? '' : l10n.chartVsLastWeek,
      deltaIsPositive: deltaIsPositive,
      isEmpty: series.isEmpty || maxRev == 0,
    );
  }

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
              value: OwnerDashboardBody.compact(summary.weekProfit),
              label: l10n.weekProfit,
              tone: KpiTone.green,
            ),
            KpiCard(
              emoji: '📊',
              value: OwnerDashboardBody.compact(summary.monthRevenue),
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
                4,
                (_) => const _SkeletonBox(height: 100),
              ),
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
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.colors.border, width: 1),
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
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.pullToRefresh,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColors.danger,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
