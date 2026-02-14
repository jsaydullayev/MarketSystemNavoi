import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/number_formatter.dart';
import '../../../screens/dashboard_screen.dart';
import '../presentation/bloc/sales_bloc.dart';
import '../presentation/bloc/events/sales_event.dart';
import '../presentation/bloc/states/sales_state.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    // Load sales on init
    context.read<SalesBloc>().add(const GetSalesEvent());
  }

  List<dynamic> _filterSales(List<dynamic> sales) {
    if (_selectedStatus == 'all') return sales;

    return sales
        .where((sale) =>
            sale['status']?.toString().toLowerCase() == _selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sotuvlar'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<SalesBloc>().add(const GetSalesEvent()),
            ),
          ],
        ),
        body: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            if (state is SalesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SalesError) {
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
                      onPressed: () => context.read<SalesBloc>().add(const GetSalesEvent()),
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              );
            } else if (state is SalesLoaded) {
              final sales = state.sales.map((e) => e.toJson()).toList();
              final filteredSales = _filterSales(sales);

              return Column(
                children: [
                  // Status filter chips
                  _buildFilterChips(),
                  // Sales list
                  Expanded(
                    child: filteredSales.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Sotuvlar yo\'q',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<SalesBloc>().add(const GetSalesEvent());
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredSales.length,
                              itemBuilder: (context, index) {
                                final sale = filteredSales[index];
                                return _buildSaleCard(context, sale);
                              },
                            ),
                          ),
                  ),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewSaleScreen()),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Yangi sotuv'),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Barchasi', 'all', Icons.receipt_long),
            const SizedBox(width: 8),
            _buildFilterChip('Davom etayotgan', 'draft', Icons.edit),
            const SizedBox(width: 8),
            _buildFilterChip('Yopilgan', 'paid', Icons.check_circle),
            const SizedBox(width: 8),
            _buildFilterChip('Qarz', 'debt', Icons.money_off),
            const SizedBox(width: 8),
            _buildFilterChip('Bekor qilingan', 'cancelled', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedStatus == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : null),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, Map<String, dynamic> sale) {
    final status = sale['status'] as String;
    final totalAmount = (sale['totalAmount'] as num).toDouble();
    final paidAmount = (sale['paidAmount'] as num).toDouble();
    final remainingAmount = (sale['remainingAmount'] as num).toDouble();
    final items = sale['items'] as List<dynamic>? ?? [];
    final itemsCount = items.length;

    Color getStatusColor() {
      switch (status.toLowerCase()) {
        case 'draft':
          return Colors.orange;
        case 'paid':
          return Colors.green;
        case 'debt':
          return Colors.red;
        case 'cancelled':
          return Colors.grey;
        default:
          return Colors.grey;
      }
    }

    String getStatusText() {
      switch (status.toLowerCase()) {
        case 'draft':
          return 'Davom etayotgan';
        case 'paid':
          return 'To\'langan';
        case 'debt':
          return 'Qarz';
        case 'cancelled':
          return 'Bekor qilingan';
        default:
          return status;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with customer name and items count
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sale['customerName'] ?? 'Mijozsiz',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (itemsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_basket,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$itemsCount',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: getStatusColor(),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  getStatusText(),
                  style: TextStyle(
                    color: getStatusColor(),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Amounts row
              Row(
                children: [
                  Expanded(
                    child: _AmountBox(
                      label: 'Jami',
                      amount: totalAmount,
                      color: getStatusColor(),
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountBox(
                      label: 'To\'langan',
                      amount: paidAmount,
                      color: Colors.green,
                    ),
                  ),
                  if (remainingAmount > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountBox(
                        label: 'Qarz',
                        amount: remainingAmount,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _AmountBox({
    required String label,
    required double amount,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            NumberFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
