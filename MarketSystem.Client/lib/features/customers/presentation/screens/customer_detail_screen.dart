import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/features/customers/presentation/widgets/debt_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import '../../../../core/utils/number_formatter.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/events/customers_event.dart';
import '../bloc/states/customers_state.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(GetCustomerDebtsEvent(widget.customerId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: widget.customerName.isNotEmpty
            ? widget.customerName
            : widget.customerPhone,
        onRefresh: () {
          context
              .read<CustomersBloc>()
              .add(GetCustomerDebtsEvent(widget.customerId));
        },
      ),
      body: BlocConsumer<CustomersBloc, CustomersState>(
        listener: (context, state) {
          if (state is CustomersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerDebtsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CustomerDebtsLoaded) {
            return _buildDebtsList(state.debts);
          } else if (state is CustomersError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<CustomersBloc>()
                  .add(GetCustomerDebtsEvent(widget.customerId)),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDebtsList(List<Map<String, dynamic>> debts) {
    final l10n = AppLocalizations.of(context)!;
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDebts,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final totalRemainingDebt = debts.fold<double>(
      0,
      (sum, debt) => sum + ((debt['remainingDebt'] as num?)?.toDouble() ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<CustomersBloc>()
            .add(GetCustomerDebtsEvent(widget.customerId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 32, color: Colors.red.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalDebt,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormatter.format(totalRemainingDebt),
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.debtHistory} (${debts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...debts.map((debt) => DebtCard(debt: debt)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
