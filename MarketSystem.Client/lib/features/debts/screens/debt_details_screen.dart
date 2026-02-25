import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/sales_service.dart';
import '../../../data/services/debt_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/number_formatter.dart';

/// Qarz detallari va tovarlarni tahrirlash screeni
class DebtDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> debt;
  final String customerName;

  const DebtDetailsScreen({
    super.key,
    required this.debt,
    required this.customerName,
  });

  @override
  State<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends State<DebtDetailsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _saleDetails;
  List<dynamic> _saleItems = [];

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtService = DebtService(authProvider: authProvider);

      final saleId = widget.debt['saleId'];
      // Get sale details - you'll need to implement this in DebtService or SaleService
      // For now, we'll use the items from debt if available

      // TODO: Load sale details from API
      // For now, assuming debt contains saleItems or we can fetch from SaleService

      setState(() {
        _isLoading = false;
        // Mock data for now - replace with actual API call
        _saleItems = widget.debt['saleItems'] ?? [];
      });
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
  }

  Future<void> _showEditPriceDialog(dynamic saleItem) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final debtStatus = widget.debt['status'];

    // Role-based check
    if (debtStatus == 'Closed' && userRole != 'Owner' && userRole != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yopilgan qarzni tahrirlash huquqi yo\'q (faqat Owner/Admin)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final priceController = TextEditingController(
      text: (saleItem['salePrice'] as num).toDouble().toString(),
    );
    final commentController = TextEditingController();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, size: 24, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(child: Text('Narxni tahrirlash')),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saleItem['productName'] ?? 'Mahsulot',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Miqdor: ${saleItem['quantity']} dona',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Eski narx: ${NumberFormatter.formatDecimal(saleItem['salePrice'])} so\'m',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New price input
                  const Text(
                    'Yangi narx:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Narx (so\'m)',
                      prefixIcon: Icon(Icons.money),
                      border: OutlineInputBorder(),
                      suffixText: "so'm",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment input (required)
                  const Text(
                    'Izoh (majburiy):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nima uchun o\'zgartiryapsiz?',
                      border: OutlineInputBorder(),
                      hintText: 'Masalan: Xato narx qo\'yilgan',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Warning for closed debts
                  if (debtStatus == 'Closed')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Diqqat: Bu qarz yopiq bo\'lgan. O\'zgartirish audit logga yoziladi.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceController.text) ?? 0;
                final comment = commentController.text.trim();

                if (newPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Narx 0 dan katta bo\'lishi kerak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (comment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Izoh kiritish majburiy'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Confirm dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tasdiqlash'),
                    content: Text(
                      'Rostdan ham narxni ${NumberFormatter.formatDecimal(newPrice)} so\'mga o\'zgartirmoqchimisiz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Yo\'q'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Ha, tasdiqlayman'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _updatePrice(saleItem, priceController.text, commentController.text);
    }
  }

  Future<void> _updatePrice(dynamic saleItem, String newPriceStr, String comment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final saleService = SalesService(authProvider: authProvider);

      final newPrice = double.parse(newPriceStr);

      await saleService.updateSaleItemPrice(
        saleItemId: saleItem['id'],
        newPrice: newPrice,
        comment: comment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Narz muvaffaqiyatli yangilandi'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data
        _loadSaleDetails();
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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final debtStatus = widget.debt['status'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz Detallari'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            widget.customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jami qarz: ${NumberFormatter.formatDecimal(widget.debt['totalDebt'])} so\'m',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Qolgan: ${NumberFormatter.formatDecimal(widget.debt['remainingDebt'])} so\'m',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: debtStatus == 'Open'
                                  ? Colors.green[100]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              debtStatus == 'Open' ? 'Ochiq' : 'Yopiq',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: debtStatus == 'Open'
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sale items list
                Expanded(
                  child: _saleItems.isEmpty
                      ? const Center(
                          child: Text('Mahsulotlar yo\'q'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _saleItems.length,
                          itemBuilder: (context, index) {
                            final item = _saleItems[index];
                            return _buildSaleItemCard(item, userRole, debtStatus);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSaleItemCard(dynamic item, String? userRole, String debtStatus) {
    final productName = item['productName'] ?? 'Noma\'lum';
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num).toDouble();
    final totalPrice = salePrice * quantity;

    // Role-based button visibility
    bool canEdit = false;
    if (debtStatus == 'Open') {
      // Open debts: All roles can edit
      canEdit = userRole != null;
    } else {
      // Closed debts: Only Owner and Admin can edit
      canEdit = userRole == 'Owner' || userRole == 'Admin';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantity dona × ${NumberFormatter.formatDecimal(salePrice)} so\'m',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  IconButton(
                    onPressed: () => _showEditPriceDialog(item),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Narxni tahrirlash',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jami:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${NumberFormatter.formatDecimal(totalPrice)} so\'m',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
