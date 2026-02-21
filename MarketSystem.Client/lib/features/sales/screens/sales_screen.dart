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
        .where((s) => s['status']?.toString().toLowerCase() == _selectedStatus)
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
              onPressed: () =>
                  context.read<SalesBloc>().add(const GetSalesEvent()),
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
                      onPressed: () =>
                          context.read<SalesBloc>().add(const GetSalesEvent()),
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
                  // Status filter buttons
                  _buildStatusFilters(sales),

                  // Sales list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<SalesBloc>().add(const GetSalesEvent());
                      },
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
                                    _selectedStatus == 'all'
                                        ? 'Sotuvlar yo\'q'
                                        : 'Bu statusdagi sotuvlar yo\'q',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredSales.length,
                              itemBuilder: (context, index) {
                                return _buildMinimalSaleCard(
                                  context,
                                  filteredSales[index],
                                );
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
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<SalesBloc>(),
                  child: const NewSaleScreen(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Yangi sotuv'),
        ),
      ),
    );
  }

  Widget _buildStatusFilters(List<dynamic> sales) {
    final allCount = sales.length;
    final draftCount = sales.where((s) =>
        s['status']?.toString().toLowerCase() == 'draft').length;
    final paidCount = sales.where((s) =>
        s['status']?.toString().toLowerCase() == 'paid').length;
    final closedCount = sales.where((s) =>
        s['status']?.toString().toLowerCase() == 'closed').length;
    final debtCount = sales.where((s) =>
        s['status']?.toString().toLowerCase() == 'debt').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton('Barchasi', 'all', allCount, Colors.blue),
            const SizedBox(width: 8),
            _buildFilterButton('Davom etayotgan', 'draft', draftCount, Colors.orange),
            const SizedBox(width: 8),
            _buildFilterButton('To\'langan', 'paid', paidCount, Colors.green),
            const SizedBox(width: 8),
            _buildFilterButton('Yopilgan', 'closed', closedCount, Colors.blue),
            const SizedBox(width: 8),
            _buildFilterButton('Qarz', 'debt', debtCount, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String status, int count, Color color) {
    final isSelected = _selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalSaleCard(BuildContext context, Map<String, dynamic> sale) {
    final status = sale['status']?.toString() ?? '';
    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = totalAmount - paidAmount;
    final items = sale['items'] as List<dynamic>? ?? [];
    final itemsCount = items.length;
    final createdAt = sale['createdAt'];

    Color getStatusColor() {
      switch (status.toLowerCase()) {
        case 'draft':
          return Colors.orange;
        case 'paid':
          return Colors.green;
        case 'closed':
          return Colors.blue;
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
        case 'closed':
          return 'Yopilgan';
        case 'debt':
          return 'Qarz';
        case 'cancelled':
          return 'Bekor qilingan';
        default:
          return status;
      }
    }

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

    // Build items preview text
    String itemsPreview = '';
    if (items.isNotEmpty) {
      final previewItems = items.take(2).toList();
      itemsPreview = previewItems.map((item) {
        final productName = item['productName'] ?? 'Noma\'lum';
        final quantity = item['quantity'] ?? 0;
        return '$quantity x $productName';
      }).join(', ');

      if (items.length > 2) {
        itemsPreview += ' +${items.length - 2} ta';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date and customer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sale['customerName'] ?? 'Mijozsiz',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      getStatusText(),
                      style: TextStyle(
                        color: getStatusColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Items preview
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    itemsPreview,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Amounts row
              Divider(
                color: Colors.grey[200],
                height: 1,
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  // Items count
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$itemsCount ta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Total amount
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: getStatusColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: getStatusColor(),
                    ),
                  ),

                  const Spacer(),

                  // Remaining amount
                  if (remainingAmount > 0) ...[
                    Icon(
                      Icons.money_off,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormatter.format(remainingAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ] else if (paidAmount > 0 && status.toLowerCase() != 'paid') ...[
                    // Faqat Paid status bo'lmaganda "To'langan" labelini ko'rsatish
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'To\'langan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
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
}
