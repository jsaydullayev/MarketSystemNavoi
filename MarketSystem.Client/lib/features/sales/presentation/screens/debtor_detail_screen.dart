import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';

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

  void _showPriceChangeDialog(dynamic saleItem, String saleId) {
    final itemId = saleItem['id'];
    final productName = saleItem['productName'];
    final currentPrice = (saleItem['salePrice'] as num?)?.toDouble() ?? 0.0;
    final quantity = (saleItem['quantity'] as num?)?.toDouble() ?? 0.0;
    final l10n = AppLocalizations.of(context)!;

    final priceController =
        TextEditingController(text: currentPrice.toString());
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double newPrice = currentPrice;

          return AlertDialog(
            title: Text('${l10n.changePrice}: $productName'),
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
                        Text('${l10n.currentPrice}:'),
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
                    decoration: InputDecoration(
                      labelText: l10n.newPriceLabel,
                      prefixIcon: const Icon(Icons.money),
                      border: const OutlineInputBorder(),
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
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n.total}: ${NumberFormatter.formatDecimal(newPrice * quantity)} ${l10n.currencySom}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.quantityCount(quantity),
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
                    decoration: InputDecoration(
                      labelText: l10n.commentOptional,
                      prefixIcon: const Icon(Icons.comment),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (newPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.priceMustBePositive),
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

                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          final salesService =
                              SalesService(authProvider: authProvider);

                          await salesService.updateSaleItemPrice(
                            saleItemId: itemId,
                            newPrice: newPrice,
                            comment: commentController.text.trim().isEmpty
                                ? l10n.priceUpdated
                                : commentController.text.trim(),
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(l10n.priceChangedFor(productName)),
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
                                content: Text('${l10n.error}: $e'),
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
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sales = widget.debtorData['sales'] as List<dynamic>? ?? [];
    final totalDebt =
        (widget.debtorData['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final paidAmount =
        (widget.debtorData['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt =
        (widget.debtorData['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: widget.customerName,
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
                          Text(
                            '${l10n.totalDebt}:',
                            style: const TextStyle(
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
                          Text(
                            '${l10n.paid}:',
                            style: const TextStyle(
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
                          Text(
                            '${l10n.remaining}:',
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
                                l10n.noSales,
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
                            final saleTotal =
                                (sale['totalAmount'] as num?)?.toDouble() ??
                                    0.0;
                            final salePaid =
                                (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
                            final saleRemaining =
                                (sale['remainingAmount'] as num?)?.toDouble() ??
                                    0.0;

                            // Format date with GMT+5 (Tashkent time)
                            final formattedDate =
                                NumberFormatter.formatDateTime(saleDate,
                                    showTime: true);
                            final formattedTime =
                                NumberFormatter.formatTime(saleDate);

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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Sana va vaqt
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          l10n.debtAmount(
                                              NumberFormatter.formatDecimal(
                                                  saleRemaining)),
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
                                    final itemName =
                                        item['productName'] ?? l10n.unknown;
                                    final itemPrice =
                                        (item['salePrice'] as num?)
                                                ?.toDouble() ??
                                            0.0;
                                    final itemQty = (item['quantity'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    final itemTotal = itemPrice * itemQty;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                NumberFormatter.formatDecimal(
                                                    itemTotal),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              // Narxni o'zgartirish tugmasi
                                              InkWell(
                                                onTap: () =>
                                                    _showPriceChangeDialog(
                                                        item, sale['id']),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        size: 12,
                                                        color: Colors
                                                            .blue.shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        l10n.changePrice,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .blue.shade700,
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
