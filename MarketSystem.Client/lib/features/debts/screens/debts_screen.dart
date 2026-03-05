import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
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
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: l10n.debts,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debtsByCustomer.isEmpty
              ? _EmptyDebtsView(onRefresh: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _debtsByCustomer.keys.length,
                    itemBuilder: (context, index) {
                      final customerId = _debtsByCustomer.keys.elementAt(index);
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
                        onPay: () => _openPaySheet(customerDebts.first, l10n),
                      );
                    },
                  ),
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 56,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.noDebts,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.allDebtsPaid,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF10B981)),
                  label: Text(
                    l10n.retry,
                    style: const TextStyle(color: Color(0xFF10B981)),
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
