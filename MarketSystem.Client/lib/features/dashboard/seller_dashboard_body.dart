import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/dashboard_service.dart';
import '../../design/tokens/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_widgets.dart';
import 'shift_control_card.dart';

class SellerDashboardBody extends StatelessWidget {
  const SellerDashboardBody({
    super.key,
    required this.role,
    this.summaryFuture,
  });

  final String role;
  final Future<SellerDashboardSummary>? summaryFuture;

  /// Compact UZS formatter for the stats row.
  String _compactUzs(double v) {
    final n = v.abs();
    if (n >= 1000000) {
      final m = v / 1000000;
      return '${m.toStringAsFixed(m.abs() >= 10 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(k.abs() >= 100 ? 0 : 1)}K';
    }
    return v.toStringAsFixed(0);
  }

  /// Thousands-grouped UZS for the draft subtitle (e.g. "42 000").
  String _grouped(double v) {
    final n = v.toStringAsFixed(0);
    final buf = StringBuffer();
    final neg = n.startsWith('-');
    final digits = neg ? n.substring(1) : n;
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
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
        if (!isAdmin) ...[
          const SizedBox(height: AppSpacing.lg),
          ShiftControlCard(
            authProvider:
                Provider.of<AuthProvider>(context, listen: false),
          ),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<SellerDashboardSummary>(
            future: summaryFuture,
            builder: (context, snapshot) {
              final summary =
                  snapshot.data ?? const SellerDashboardSummary();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary.pendingDraft case final d?)
                    PendingSaleCard(
                      title: l10n.oneSaleInProgress,
                      subtitle: '${d.itemCount} ${l10n.unitPiece} · '
                          '${_grouped(d.totalAmount)} UZS',
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
                        value:
                            '${summary.myShiftDurationHours} ${l10n.hour}',
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
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.cashRegister),
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
