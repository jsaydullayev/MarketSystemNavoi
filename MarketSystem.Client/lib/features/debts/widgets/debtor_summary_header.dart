// Qarzdor kartasiga bosilganda chiqadigan yig'ma sarlavha.
//
// Bitta mijoz bir necha marta qarz olishi mumkin, shuning uchun bu yerda uchta
// raqam ko'rsatiladi:
//   1) JAMI QARZ           — barcha ochiq qarzlarning qoldig'i;
//   2) HOZIRGI OLINGAN QARZ — eng oxirgi olingan qarzning summasi va sanasi;
//   3) OXIRGI TO'LOV        — oxirgi marta qarzga to'langan summa, sanasi/turi.
//
// Aynan shu uchlik backend'dagi `CustomerDebtSummaryBuilder` orqali PDF
// hisobotga ham chiziladi, ya'ni ekran va PDF raqamlari bir xil.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/models/customer_debt_summary.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DebtorSummaryHeader extends StatelessWidget {
  const DebtorSummaryHeader({
    super.key,
    required this.summary,
    required this.fallbackTotalDebt,
    required this.fallbackTakenTotal,
    required this.fallbackDebtCount,
  });

  /// Backend'dan kelgan yig'ma ma'lumot. Hali yuklanmagan (yoki 404) bo'lsa
  /// null — bunda quyidagi `fallback*` qiymatlar ishlatiladi, shunda ekran
  /// bo'sh turmaydi.
  final CustomerDebtSummary? summary;

  /// Mahalliy ro'yxatdan hisoblangan qoldiq yig'indisi.
  final double fallbackTotalDebt;

  /// Mahalliy ro'yxatdan hisoblangan boshlang'ich summalar yig'indisi.
  final double fallbackTakenTotal;

  final int fallbackDebtCount;

  double get _totalDebt => summary?.totalDebt ?? fallbackTotalDebt;
  double get _takenTotal => summary?.totalOriginalDebt ?? fallbackTakenTotal;
  double get _paid => summary?.totalPaid ?? (fallbackTakenTotal - fallbackTotalDebt);
  int get _debtCount => summary?.openDebtCount ?? fallbackDebtCount;

  static String _fmtDate(DateTime? date) =>
      date == null ? '—' : DateFormat('dd.MM.yyyy').format(date.toLocal());

  static String _fmtDateTime(DateTime? date) =>
      date == null ? '—' : DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());

  /// Backend `PaymentType` enum nomini tarjima qilingan yorliqqa o'giradi.
  static String _paymentLabel(String? type, AppLocalizations l10n) {
    switch (type) {
      case 'Cash':
        return l10n.cash;
      case 'Terminal':
        return l10n.card;
      case 'Transfer':
        return l10n.transfer;
      case 'Click':
        return l10n.click;
      case null:
      case '':
        return '';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = summary;

    return Column(
      children: [
        // ── 1. Jami qarz — amber gradient karta ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.warningDark, AppColors.warning],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.totalDebt.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${NumberFormatter.format(_totalDebt)} ${l10n.currencySom}',
                  style: AppTextStyles.titleLarge().copyWith(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniFact(
                      label: l10n.takenTotalLabel,
                      value: NumberFormatter.format(_takenTotal),
                    ),
                  ),
                  Expanded(
                    child: _MiniFact(
                      label: l10n.paidLabel,
                      value: NumberFormatter.format(_paid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.debtCount(_debtCount),
                style: AppTextStyles.bodySmall().copyWith(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 2 va 3. Hozirgi olingan qarz + Oxirgi to'lov ──
        // IntrinsicHeight kerak: `stretch` ko'ndalang o'lchamni cheksiz
        // konstreyntda hisoblab bo'lmaydi (ListView ichida balandlik cheksiz),
        // shu sababli ikkita karta layout'da yiqilib, ekran bo'sh qolardi.
        // IntrinsicHeight Row balandligini eng baland kartaga tenglashtiradi —
        // natijada ikkalasi bir xil o'lchamda turadi.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.shopping_bag_rounded,
                  accent: context.colors.brand,
                  label: l10n.lastTakenDebt,
                  amount: s?.lastDebtAmount ?? 0,
                  caption: s?.lastDebtDate == null
                      ? '—'
                      : '${_fmtDate(s!.lastDebtDate)} · ${l10n.remainingDebtLabel} '
                            '${NumberFormatter.format(s.lastDebtRemaining)}',
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _StatTile(
                  icon: Icons.payments_rounded,
                  accent: AppColors.success,
                  label: l10n.lastDebtPayment,
                  amount: s?.lastPaymentAmount ?? 0,
                  caption: (s == null || !s.hasPayment)
                      ? l10n.noPaymentYet
                      : [
                          _fmtDateTime(s.lastPaymentDate),
                          _paymentLabel(s.lastPaymentType, l10n),
                        ].where((p) => p.isNotEmpty).join(' · '),
                  dimmed: s == null || !s.hasPayment,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium().copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// "Hozirgi olingan qarz" / "Oxirgi to'lov" uchun bir xil o'lchamdagi karta.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.amount,
    required this.caption,
    this.dimmed = false,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final double amount;
  final String caption;

  /// To'lov hali bo'lmaganida summa 0 — uni asosiy rangda ko'rsatish
  /// chalg'itadi, shuning uchun so'nadi.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption().copyWith(fontSize: 10.5),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${NumberFormatter.format(amount)} ${l10n.currencySom}',
              style: AppTextStyles.bodyMedium().copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: dimmed ? context.colors.textMuted : accent,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: AppTextStyles.caption().copyWith(
              fontSize: 10,
              color: context.colors.textMuted,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
