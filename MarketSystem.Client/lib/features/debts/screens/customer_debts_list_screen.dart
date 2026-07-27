// Bitta mijozning BARCHA ochiq qarzlarini ko'rsatadigan ekran.
//
// Nega kerak: qarzlar ro'yxatidagi karta mijozning qarzlarini JAMLAB
// ko'rsatadi (masalan 3 ta qarz = 10 720 000 so'm), lekin har bir qarz aslida
// alohida sotuv (o'z id/saleItems/dueDate'i bilan) va backend to'lovni
// qarz-ma-qarz (`payDebt(debtId)`) qabul qiladi. Ilgari kartaga bosilganda
// faqat `firstOrNull` — ya'ni bitta qarz — ochilardi, shu sabab foydalanuvchi
// jami 10 720 000 o'rniga faqat oxirgi 480 000 so'mlik qarzni ko'rardi.
//
// Bu ekran mijozning har bir ochiq qarzini alohida qator qilib chiqaradi:
// har birini ko'rish (DebtDetailsScreen) yoki to'lash (PayDebtBottomSheet)
// mumkin, tepada esa jami yig'indi turadi.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/data/services/debt_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/debts/widgets/due_date_badge.dart';
import 'package:market_system_client/features/debts/widgets/pay_debt_bottomsheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permissions.dart';
import 'debt_details_screen.dart';

class CustomerDebtsListScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  /// Ro'yxat darhol ko'rinishi uchun ota-ekrandan (getAllDebts natijasidan)
  /// kelgan boshlang'ich qarzlar. initState fonda yangisini tortadi.
  final List<dynamic> initialDebts;

  const CustomerDebtsListScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.initialDebts,
  });

  @override
  State<CustomerDebtsListScreen> createState() =>
      _CustomerDebtsListScreenState();
}

class _CustomerDebtsListScreenState extends State<CustomerDebtsListScreen> {
  late List<dynamic> _debts;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _debts = List<dynamic>.from(widget.initialDebts);
    _refresh();
  }

  /// Ochiq qarzlarni qayta tortadi. getAllDebts(status:'Open') ota-ekran bilan
  /// AYNAN bir xil DTO (saleItems bilan) qaytaradi — shu sabab bu yerdan
  /// DebtDetailsScreen'ga o'tilganda mahsulotlar to'liq ko'rinadi.
  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtService = DebtService(authProvider: authProvider);
      final all = await debtService.getAllDebts(status: 'Open');
      final mine = all
          .where((d) => d['customerId'] == widget.customerId)
          .toList();
      if (!mounted) return;
      setState(() {
        _debts = mine;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorParser.parse(e.toString())),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  double get _totalDebt => _debts.fold(
    0.0,
    (sum, d) => sum + ((d['totalDebt'] as num?)?.toDouble() ?? 0),
  );

  double get _remaining => _debts.fold(
    0.0,
    (sum, d) => sum + ((d['remainingDebt'] as num?)?.toDouble() ?? 0),
  );

  Future<void> _openDetails(dynamic debt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DebtDetailsScreen(
          debt: debt,
          customerName: widget.customerName,
        ),
      ),
    );
    // Qaytgach — narx tahriri qarz summasini o'zgartirgan bo'lishi mumkin.
    if (mounted) _refresh();
  }

  void _openPaySheet(dynamic debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayDebtBottomSheet(
        debt: debt,
        customerName: widget.customerName,
        onSuccess: _refresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).can(Permissions.debtsManage);

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: CommonAppBar(title: widget.customerName, onRefresh: _refresh),
      body: _debts.isEmpty
          ? Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      l10n.noDebts,
                      style: AppTextStyles.titleMedium().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl3,
                ),
                itemCount: _debts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AggregateHeader(
                      totalDebt: _totalDebt,
                      remaining: _remaining,
                      debtCount: _debts.length,
                    );
                  }
                  final debt = _debts[index - 1];
                  return _DebtRowCard(
                    debt: debt,
                    index: index,
                    canManage: canManage,
                    onTap: () => _openDetails(debt),
                    onPay: () => _openPaySheet(debt),
                  );
                },
              ),
            ),
    );
  }
}

/// Mijozning barcha ochiq qarzlari yig'indisi — amber gradient karta.
class _AggregateHeader extends StatelessWidget {
  const _AggregateHeader({
    required this.totalDebt,
    required this.remaining,
    required this.debtCount,
  });

  final double totalDebt;
  final double remaining;
  final int debtCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
        children: [
          _HeaderRow(
            label: l10n.totalDebt,
            value: NumberFormatter.format(totalDebt),
            currency: l10n.currencySom,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),
          _HeaderRow(
            label: l10n.remaining,
            value: NumberFormatter.format(remaining),
            currency: l10n.currencySom,
            isBig: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.debtCount(debtCount),
              style: AppTextStyles.bodySmall().copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.label,
    required this.value,
    required this.currency,
    this.isBig = false,
  });

  final String label;
  final String value;
  final String currency;
  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isBig ? 14 : 13,
          ),
        ),
        Text(
          '$value $currency',
          style:
              (isBig ? AppTextStyles.titleLarge() : AppTextStyles.bodyMedium())
                  .copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
        ),
      ],
    );
  }
}

/// Bitta qarz (bitta sotuv) qatori — ko'rish uchun bosiladi, alohida to'lanadi.
class _DebtRowCard extends StatelessWidget {
  const _DebtRowCard({
    required this.debt,
    required this.index,
    required this.canManage,
    required this.onTap,
    required this.onPay,
  });

  final dynamic debt;
  final int index;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onPay;

  String get _dateLabel {
    final raw = debt['createdAt'];
    if (raw == null) return '';
    try {
      final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = (debt['totalDebt'] as num?)?.toDouble() ?? 0;
    final remaining = (debt['remainingDebt'] as num?)?.toDouble() ?? 0;
    final hasDebt = remaining > 0;
    final dueRaw = debt['dueDate'];
    final itemCount = (debt['saleItems'] as List?)?.length ?? 0;
    final dateLabel = _dateLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: context.colors.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: context.colors.brand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sotuv #$index',
                            style: AppTextStyles.labelLarge().copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (dateLabel.isNotEmpty) dateLabel,
                              if (itemCount > 0)
                                '$itemCount ${l10n.piece}',
                            ].join(' · '),
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg + 2,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AmountItem(
                          label: l10n.totalDebt,
                          amount: total,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: context.colors.border,
                      ),
                      Expanded(
                        child: _AmountItem(
                          label: l10n.remaining,
                          amount: remaining,
                          color: AppColors.danger,
                          isBold: true,
                          align: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                ),
                if (DueDateBadge.parse(dueRaw) != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DueDateBadge(dueDate: dueRaw),
                  ),
                ],
                if (hasDebt && canManage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppSuccessButton(
                    label: l10n.pay,
                    icon: Icons.payment_rounded,
                    onPressed: onPay,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  const _AmountItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: AppTextStyles.caption().copyWith(fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          '${NumberFormatter.format(amount)} ${l10n.currencySom}',
          style: AppTextStyles.bodyMedium().copyWith(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
