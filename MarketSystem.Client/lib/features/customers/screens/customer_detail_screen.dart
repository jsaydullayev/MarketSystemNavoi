import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/number_formatter.dart';
import '../../sales/screens/sale_detail_screen.dart';
import '../presentation/bloc/customers_bloc.dart';
import '../presentation/bloc/events/customers_event.dart';
import '../presentation/bloc/states/customers_state.dart';

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
    // Load customer debts
    context.read<CustomersBloc>().add(GetCustomerDebtsEvent(widget.customerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName.isNotEmpty ? widget.customerName : widget.customerPhone),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CustomersBloc>().add(GetCustomerDebtsEvent(widget.customerId));
            },
          ),
        ],
      ),
      body: BlocListener<CustomersBloc, CustomersState>(
        listener: (context, state) {
          if (state is CustomersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CustomersBloc, CustomersState>(
          builder: (context, state) {
            if (state is CustomerDebtsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CustomerDebtsLoaded) {
              return _buildDebtsList(state.debts);
            } else if (state is CustomersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CustomersBloc>().add(GetCustomerDebtsEvent(widget.customerId));
                      },
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildDebtsList(List<Map<String, dynamic>> debts) {
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
              'Qarzlar yo\'q',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate total remaining debt
    final totalRemainingDebt = debts.fold<double>(
      0,
      (sum, debt) => sum + ((debt['remainingDebt'] as num?)?.toDouble() ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CustomersBloc>().add(GetCustomerDebtsEvent(widget.customerId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total debt card
          Card(
            elevation: 4,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 32, color: Colors.red.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jami qarz',
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

          // Debts list
          Text(
            'Qarzlar tarixi (${debts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          ...debts.map((debt) => _buildDebtCard(debt)),
        ],
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> debt) {
    final totalDebt = (debt['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (debt['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final saleId = debt['saleId']?.toString() ?? '';
    final status = debt['status']?.toString() ?? 'Open';
    final createdAt = debt['createdAt'];

    // Format date
    String formattedDate = 'Noma\'lum';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate =
            '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdAt.toString();
      }
    }

    final isOpen = status.toLowerCase() == 'open';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOpen ? Colors.red.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (saleId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleDetailScreen(saleId: saleId),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isOpen
                ? LinearGradient(
                    colors: [Colors.red.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date + Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.red.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOpen ? Colors.red : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOpen ? Icons.money_off : Icons.check_circle,
                            size: 14,
                            color: isOpen ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Qarzda' : 'Tugatilgan',
                            style: TextStyle(
                              color: isOpen ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amounts
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountColumn(
                        label: 'Jami summa',
                        amount: totalDebt,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountColumn(
                        label: 'Qolgan qarz',
                        amount: remainingDebt,
                        color: isOpen ? Colors.red : Colors.green,
                        isMain: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Tap to view details
                Center(
                  child: Text(
                    'Tovarlarni ko\'rish uchun bosing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required double amount,
    required Color color,
    bool isMain = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormatter.format(amount),
          style: TextStyle(
            fontSize: isMain ? 18 : 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
