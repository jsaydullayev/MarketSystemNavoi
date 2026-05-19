import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/debts/widgets/customer_debt_card.dart';
import 'package:market_system_client/features/debts/widgets/pay_debt_bottomsheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../data/services/debt_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'debt_details_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: CommonAppBar(
        title: l10n.debts,
        onRefresh: _loadData,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debtsByCustomer.isEmpty
              ? _EmptyDebtsView(onRefresh: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.md, AppSpacing.xl,
                        AppSpacing.xl3),
                    children: [
                      _DebtsHero(
                        totalRemaining: _totalRemaining,
                        debtorCount: _debtsByCustomer.length,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (final customerId in _debtsByCustomer.keys) ...[
                        Builder(
                          builder: (context) {
                            final customerDebts =
                                _debtsByCustomer[customerId]!;
                            final customerName =
                                _customerNames[customerId] ?? l10n.unknown;

                            double totalDebt = 0;
                            double remainingDebt = 0;
                            for (var d in customerDebts) {
                              totalDebt +=
                                  (d['totalDebt'] as num).toDouble();
                              remainingDebt +=
                                  (d['remainingDebt'] as num).toDouble();
                            }

                            return CustomerDebtCard(
                              customerName: customerName,
                              customerDebts: customerDebts,
                              totalDebt: totalDebt,
                              remainingDebt: remainingDebt,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DebtDetailsScreen(
                                    debt: customerDebts.first,
                                    customerName: customerName,
                                  ),
                                ),
                              ),
                              onPay: () =>
                                  _openPaySheet(customerDebts.first, l10n),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

/// Amber gradient hero showing the aggregate "JAMI QARZ" across all open debts.
class _DebtsHero extends StatelessWidget {
  const _DebtsHero(
      {required this.totalRemaining, required this.debtorCount});
  final double totalRemaining;
  final int debtorCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
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
                Text(
                  l10n.allDebtsPaid,
                  style: AppTextStyles.bodySmall(),
                ),
                const SizedBox(height: AppSpacing.xl3),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.success),
                  label: Text(
                    l10n.retry,
                    style: AppTextStyles.bodyMedium()
                        .copyWith(color: AppColors.success),
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
