import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/number_formatter.dart';
import '../presentation/bloc/sales_bloc.dart';
import '../presentation/bloc/events/sales_event.dart';
import '../presentation/bloc/states/sales_state.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({
    super.key,
    required this.saleId,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool _showReturnSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    // Load sale details
    _loadSaleDetails();
  }

  void _loadSaleDetails() {
    context.read<SalesBloc>().add(GetSaleDetailEvent(widget.saleId));
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
        } else if (state is SaleItemReturned) {
          // Muvaffaqiyatlik xabarni ko'rsatish
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tovar muvaffaqiyatli qaytarildi'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Savdo detallarini qayta yuklash
          _loadSaleDetails();
        } else if (state is SaleDetailLoaded && _showReturnSuccessMessage) {
          // Yangilangan ma'lumotlar kelgandan keyin yana xabar ko'rsatish
          setState(() {
            _showReturnSuccessMessage = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sotuv tafsilotlari'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSaleDetails,
            ),
          ],
        ),
        body: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            if (state is SaleDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SaleDetailLoaded) {
              return _buildSaleDetail(state.sale);
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
                      onPressed: _loadSaleDetails,
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

  Widget _buildSaleDetail(Map<String, dynamic> sale) {
    final status = sale['status']?.toString() ?? '';
    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = totalAmount - paidAmount;
    final items = sale['items'] as List<dynamic>? ?? [];

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale info card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sale['customerName'] ?? 'Mijozsiz',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: getStatusColor(),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          getStatusText(),
                          style: TextStyle(
                            color: getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (sale['customerPhone'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          sale['customerPhone'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Sotuvchi: ${sale['sellerName'] ?? "Noma'lum"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(sale['createdAt']),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items section
          const Text(
            'Sotilgan mahsulotlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mahsulotlar yo\'q',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index] as Map<String, dynamic>;
                    return _buildItemCard(item);
                  },
                ),

          const SizedBox(height: 16),

          // Summary card
          Card(
            elevation: 4,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jami summa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Jami:',
                    totalAmount,
                    Colors.black,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'To\'langan:',
                    paidAmount,
                    Colors.green,
                  ),
                  if (remainingAmount > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Qarz:',
                      remainingAmount,
                      Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final productName = item['productName'] ?? 'Noma\'lum mahsulot';
    final quantity = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 0.0;  // ✅ DECIMAL
    final salePrice = (item['salePrice'] as num).toDouble();
    final totalPrice = (item['totalPrice'] as num).toDouble();

    // Savdo statusini olish - faqat yopilgan savdolarda vozvrat tugmasi ko'rsatiladi
    final saleData = (context.read<SalesBloc>().state is SaleDetailLoaded)
        ? (context.read<SalesBloc>().state as SaleDetailLoaded).sale
        : null;
    final status = saleData?['status']?.toString().toLowerCase() ?? '';
    final canReturn = status == 'paid' || status == 'debt';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$quantity ta x ${NumberFormatter.formatDecimal(salePrice)} so\'m',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (canReturn)
              IconButton(
                icon: const Icon(Icons.keyboard_return, color: Colors.orange),
                tooltip: 'Tovarni qaytarish',
                onPressed: () => _showReturnDialog(item),
              ),
            const SizedBox(width: 8),
            Text(
              '${NumberFormatter.formatDecimal(totalPrice)} so\'m',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          '${NumberFormatter.formatDecimal(amount)} so\'m',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Noma\'lum';

    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      dateTime = DateTime.parse(date);
    } else {
      return 'Noma\'lum';
    }

    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showReturnDialog(Map<String, dynamic> item) {
    final productName = item['productName'] ?? 'Noma\'lum mahsulot';
    final saleItemId = item['id']?.toString() ?? '';
    final maxQuantity = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 0.0;  // ✅ DECIMAL
    final salePrice = (item['salePrice'] as num).toDouble();

    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Qaytarish mumkin bo\'lgan miqdor yo\'q'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantityController = TextEditingController(text: '1');
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.keyboard_return, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tovarni qaytarish',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mahsulot ma'lumotlari
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Narxi: ${NumberFormatter.formatDecimal(salePrice)} so\'m',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Maksimal miqdor: $maxQuantity ta',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Miqdor input
                  const Text(
                    'Qaytariladigan miqdor:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: '1',
                      suffixText: 'ta',
                      prefixIcon: const Icon(Icons.format_list_numbered),
                    ),
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Izoh input
                  const Text(
                    'Izoh (ixtiyoriy):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Qaytarish sababi...',
                      prefixIcon: Icon(Icons.comment),
                    ),
                  ),

                  // Jami summa
                  if (quantityController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Qaytariladigan summa:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${NumberFormatter.formatDecimal(_getReturnAmount(quantityController.text, salePrice))} so\'m',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                onPressed: () => _processReturn(
                  saleItemId,
                  quantityController.text,
                  commentController.text,
                  maxQuantity,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Qaytarish'),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getReturnAmount(String quantityStr, double salePrice) {
    final quantity = double.tryParse(quantityStr) ?? 0.0;  // ✅ DECIMAL
    return quantity * salePrice;
  }

  void _processReturn(
    String saleItemId,
    String quantityStr,
    String comment,
    double maxQuantity,  // ✅ DECIMAL
  ) {
    final quantity = double.tryParse(quantityStr);  // ✅ DECIMAL

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri miqdor kiriting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (quantity > maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal miqdor: $maxQuantity'),  // ✅ "ta" olib tashlandi
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dialogni yopish
    Navigator.of(context).pop();

    // Flag qo'yish - yangilangan ma'lumotlar kelganda xabar ko'rsatamiz
    _showReturnSuccessMessage = true;

    // Vozvrat qilish
    context.read<SalesBloc>().add(
          ReturnSaleItemEvent(
            saleId: widget.saleId,
            saleItemId: saleItemId,
            quantity: quantity.toDouble(),
            comment: comment.isEmpty ? null : comment,
          ),
        );
  }
}
