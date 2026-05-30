import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/debts/widgets/customer_debt_card.dart';
import 'package:market_system_client/features/debts/widgets/pay_debt_bottomsheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../data/services/debt_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'debt_details_screen.dart';

/// Client-side ordering for the debt-list view. The backend already filters
/// to status='Open' so the chips just re-shuffle the same list — keeps the
/// surface aligned with the demo's "Hammasi / Qarzdorlar / …" filter row
/// without inventing new endpoints.
enum _DebtSort { all, largest, recent }

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  Map<String, List<dynamic>> _debtsByCustomer = {};
  Map<String, String> _customerNames = {};
  bool _isLoading = false;
  bool _initialized = false;
  _DebtSort _sort = _DebtSort.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtService = DebtService(authProvider: authProvider);
      final debts = await debtService.getAllDebts(status: 'Open');

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      final Map<String, List<dynamic>> grouped = {};
      final Map<String, String> names = {};
      for (var debt in debts) {
        final customerId = debt['customerId'];
        if (!grouped.containsKey(customerId)) {
          grouped[customerId] = [];
          names[customerId] = debt['customerName'] ?? l10n.unknown;
        }
        grouped[customerId]!.add(debt);
      }

      setState(() {
        _debtsByCustomer = grouped;
        _customerNames = names;
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

  void _openPaySheet(dynamic debt, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayDebtBottomSheet(
        debt: debt,
        customerName: _customerNames[debt['customerId']] ?? l10n.unknown,
        onSuccess: _loadData,
      ),
    );
  }

  double get _totalRemaining {
    double sum = 0;
    for (final debts in _debtsByCustomer.values) {
      for (final d in debts) {
        sum += ((d['remainingDebt'] as num?)?.toDouble() ?? 0);
      }
    }
    return sum;
  }

  /// Sum of remaining debt per customer-id, used by the chip sort.
  double _customerTotal(String customerId) {
    double sum = 0;
    for (final d in _debtsByCustomer[customerId] ?? const []) {
      sum += ((d['remainingDebt'] as num?)?.toDouble() ?? 0);
    }
    return sum;
  }

  /// Most recent `createdAt` on any debt row for a customer — used to sort
  /// the "Yangi" filter chip without touching the backend.
  DateTime _customerMostRecent(String customerId) {
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final d in _debtsByCustomer[customerId] ?? const []) {
      final raw = d['createdAt'];
      if (raw == null) continue;
      try {
        final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
        if (dt.isAfter(latest)) latest = dt;
      } catch (_) {
        // Ignore rows with un-parseable timestamps; they sort to the bottom.
      }
    }
    return latest;
  }

  /// Customer-id order under the currently selected chip.
  List<String> _sortedCustomerIds() {
    final ids = _debtsByCustomer.keys.toList();
    switch (_sort) {
      case _DebtSort.all:
        return ids;
      case _DebtSort.largest:
        ids.sort((a, b) => _customerTotal(b).compareTo(_customerTotal(a)));
        return ids;
      case _DebtSort.recent:
        ids.sort(
          (a, b) => _customerMostRecent(b).compareTo(_customerMostRecent(a)),
        );
        return ids;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: CommonAppBar(title: l10n.debts, onRefresh: _loadData),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debtsByCustomer.isEmpty
          ? _EmptyDebtsView(onRefresh: _loadData)
          : Builder(
              builder: (context) {
                // Hero + sort chips render once; only the debtor cards are
                // built lazily via ListView.builder. _sortedCustomerIds() is
                // computed once per build instead of being re-walked inline.
                final ids = _sortedCustomerIds();
                final leading = <Widget>[
                  _DebtsHero(
                    totalRemaining: _totalRemaining,
                    debtorCount: _debtsByCustomer.length,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DebtSortChips(
                    active: _sort,
                    onChanged: (s) => setState(() => _sort = s),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ];
                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xl3,
                    ),
                    itemCount: leading.length + ids.length,
                    itemBuilder: (context, index) {
                      if (index < leading.length) return leading[index];
                      final customerId = ids[index - leading.length];
                      final customerDebts = _debtsByCustomer[customerId]!;
                      final customerName =
                          _customerNames[customerId] ?? l10n.unknown;

                      double totalDebt = 0;
                      double remainingDebt = 0;
                      for (var d in customerDebts) {
                        totalDebt += (d['totalDebt'] as num).toDouble();
                        remainingDebt += (d['remainingDebt'] as num).toDouble();
                      }

                      return CustomerDebtCard(
                        key: ValueKey('debt_$customerId'),
                        customerName: customerName,
                        customerDebts: customerDebts,
                        totalDebt: totalDebt,
                        remainingDebt: remainingDebt,
                        onTap: () {
                          final debt = customerDebts.firstOrNull;
                          if (debt == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DebtDetailsScreen(
                                debt: debt,
                                customerName: customerName,
                              ),
                            ),
                          );
                        },
                        onPay: () {
                          final debt = customerDebts.firstOrNull;
                          if (debt != null) _openPaySheet(debt, l10n);
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

/// Horizontal chip row that re-orders the debt list. Labels reuse existing
/// l10n keys (`all`, `debtor`, `today`) so we don't have to extend the .arb
/// for this view alone.
class _DebtSortChips extends StatelessWidget {
  const _DebtSortChips({required this.active, required this.onChanged});

  final _DebtSort active;
  final ValueChanged<_DebtSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ChipPill(
            label: l10n.all,
            isActive: active == _DebtSort.all,
            onTap: () => onChanged(_DebtSort.all),
          ),
          const SizedBox(width: AppSpacing.md),
          _ChipPill(
            label: '${l10n.debtor} ↑',
            isActive: active == _DebtSort.largest,
            onTap: () => onChanged(_DebtSort.largest),
          ),
          const SizedBox(width: AppSpacing.md),
          _ChipPill(
            label: l10n.today,
            isActive: active == _DebtSort.recent,
            onTap: () => onChanged(_DebtSort.recent),
          ),
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? context.colors.brand : context.colors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? context.colors.brand : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: isActive
                ? context.colors.onBrand
                : context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Amber gradient hero showing the aggregate "JAMI QARZ" across all open debts.
class _DebtsHero extends StatelessWidget {
  const _DebtsHero({required this.totalRemaining, required this.debtorCount});
  final double totalRemaining;
  final int debtorCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        // Same amber "JAMI QARZ" gradient as the customers list hero —
        // tokenised so a future palette tweak only happens in one place.
        gradient: const LinearGradient(
          colors: [AppColors.warningDark, AppColors.warning],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalDebt.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            child: Text(
              '${NumberFormatter.format(totalRemaining)} ${l10n.currencySom}',
              style: AppTextStyles.displayLarge().copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$debtorCount ${l10n.debtor.toLowerCase()}',
            style: AppTextStyles.bodySmall().copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDebtsView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyDebtsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl3),
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 56,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),
                Text(l10n.noDebts, style: AppTextStyles.titleMedium()),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.allDebtsPaid, style: AppTextStyles.bodySmall()),
                const SizedBox(height: AppSpacing.xl3),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.success,
                  ),
                  label: Text(
                    l10n.retry,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
