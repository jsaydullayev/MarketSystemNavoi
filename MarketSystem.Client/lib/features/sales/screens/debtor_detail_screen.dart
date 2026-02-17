import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/sales_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/number_formatter.dart';

/// Qarzdor Detail Screeni
/// Mijozning qarzli savdolari va tovarlari
class DebtorDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final Map<String, dynamic> debtorData;

  const DebtorDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.debtorData,
  });

  @override
  State<DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<DebtorDetailScreen> {
  bool _isLoading = false;

  // Narxni o'zgartirish dialogi
  void _showPriceChangeDialog(dynamic saleItem, String saleId) {
    final itemId = saleItem['id'];
    final productName = saleItem['productName'];
    final currentPrice = (saleItem['salePrice'] as num?)?.toDouble() ?? 0.0;
    final quantity = saleItem['quantity'] ?? 0;

    final priceController = TextEditingController(text: currentPrice.toString());
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double newPrice = currentPrice;

          return AlertDialog(
            title: Text('Narxni o\'zgartirish: $productName'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hozirgi narx
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hozirgi narx:'),
                        Text(
                          NumberFormatter.formatDecimal(currentPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Yangi narx kiritish
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Yangi narx (so\'m)',
                      prefixIcon: Icon(Icons.money),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        newPrice = double.tryParse(value) ?? currentPrice;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Ma'lumot
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Jami: ${NumberFormatter.formatDecimal(newPrice * quantity)} so\'m',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Miqdor: $quantity ta',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Izoh
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Izoh (ixtiyoriy)',
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (newPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Narx musbat bo\'lishi kerak!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        try {
                          setState(() {
                          _isLoading = true;
                        });

                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final salesService = SalesService(authProvider: authProvider);

                        await salesService.updateSaleItemPrice(
                          saleItemId: itemId,
                          newPrice: newPrice,
                          comment: commentController.text.trim().isEmpty
                              ? 'Narx yangilandi'
                              : commentController.text.trim(),
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$productName uchun narx o\'zgartirildi'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh data
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });

                        if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Xatolik: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Saqlash'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = widget.debtorData['sales'] as List<dynamic>? ?? [];
    final totalDebt = (widget.debtorData['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (widget.debtorData['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (widget.debtorData['remainingDebt'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.customerName),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade200,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jami qarz:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            NumberFormatter.formatDecimal(totalDebt),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'To\'langan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            NumberFormatter.formatDecimal(paidAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Qolgan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            NumberFormatter.formatDecimal(remainingDebt),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sales list
                Expanded(
                  child: sales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Savdolar yo\'q',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sales.length,
                          itemBuilder: (context, saleIndex) {
                            final sale = sales[saleIndex];
                            final items = sale['items'] as List<dynamic>? ?? [];
                            final saleDate = sale['createdAt'];
                            final saleTotal = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
                            final salePaid = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
                            final saleRemaining = (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;

                            // Format date
                            String formattedDate = 'Noma\'lum';
                            try {
                              final date = DateTime.parse(saleDate);
                              formattedDate = '${date.day}.${date.month}.${date.year}';
                            } catch (e) {
                              formattedDate = saleDate.toString();
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sale header
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          'Qarz: ${NumberFormatter.formatDecimal(saleRemaining)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Items
                                  ...items.map((item) {
                                    final itemName = item['productName'] ?? 'Noma\'lum';
                                    final itemPrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
                                    final itemQty = item['quantity'] ?? 0;
                                    final itemTotal = itemPrice * itemQty;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  itemName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '$itemQty x ${NumberFormatter.format(itemPrice)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                NumberFormatter.formatDecimal(itemTotal),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              // Narxni o'zgartirish tugmasi
                                              InkWell(
                                                onTap: () => _showPriceChangeDialog(item, sale['id']),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                              Icon(
                                                                Icons.edit,
                                                                size: 12,
                                                                color: Colors.blue.shade700,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                'Narxni o\'zgartirish',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.blue.shade700,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
