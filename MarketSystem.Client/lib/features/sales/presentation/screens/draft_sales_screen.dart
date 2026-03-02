import 'package:market_system_client/features/sales/presentation/screens/%20continue_sale_screen.dart';
import 'package:market_system_client/features/sales/presentation/widgets/customer_selection_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/debtor_payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/draft_sale_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/section_header.dart';
import 'package:market_system_client/features/sales/presentation/widgets/debtor_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/empty_state.dart';
import 'package:market_system_client/features/sales/presentation/widgets/payment_history_dialog.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../core/providers/auth_provider.dart';

/// Draft Savdolar Screeni
/// Seller o'zining tugatilmagan savdolarini ko'radi va davom ettiradi
class DraftSalesScreen extends StatefulWidget {
  const DraftSalesScreen({super.key});

  @override
  State<DraftSalesScreen> createState() => _DraftSalesScreenState();
}

class _DraftSalesScreenState extends State<DraftSalesScreen> {
  List<dynamic> _unfinishedSales = [];
  List<dynamic> _debtors = [];
  bool _isLoading = true;

  // Guruhlangan savdolar
  List<dynamic> get _draftSales =>
      _unfinishedSales.where((s) => s['status'] == 'Draft').toList();
  List<dynamic> get _debtSales =>
      _unfinishedSales.where((s) => s['status'] == 'Debt').toList();
  List<dynamic> get _paidSales =>
      _unfinishedSales.where((s) => s['status'] == 'Paid').toList();

  @override
  void initState() {
    super.initState();
    _loadDraftSales();
    _loadDebtors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      Future.delayed(Duration.zero, () {
        _loadDraftSales();
        _loadDebtors();
      });
    }
  }

  Future<void> _loadDraftSales() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final unfinished = await salesService.getMyUnfinishedSales();
      setState(() {
        _unfinishedSales = unfinished;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadDebtors() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final debtors = await salesService.getDebtors();
      if (mounted) setState(() => _debtors = debtors);
    } catch (e) {
      debugPrint('Error loading debtors: $e');
    }
  }

  Future<void> _continueSale(dynamic draftSale) async {
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContinueSaleScreen(saleId: draftSale['id']),
      ),
    );
    if (result == true) _loadDraftSales();
  }

  void _confirmDelete(String saleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Savdoni o\'chirish'),
        content: const Text('Haqiqatan ham bu savdoni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final salesService = SalesService(authProvider: authProvider);
                await salesService.deleteSale(saleId: saleId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Savdo o\'chirildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDraftSales();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Savdoni o\'chirishda xatolik: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child:
                const Text('O\'chirish', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(dynamic sale) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomerSelectionDialog(
        saleId: sale['id'],
        onCustomerSelected: () {
          _loadDraftSales();
        },
      ),
    );
  }

  void _openEditDialog(dynamic sale) {
    _continueSale(sale);
  }

  void _confirmDelete(String saleId) {
    _showDeleteConfirmation(saleId);
  }

  Widget _buildDraftSaleCard(dynamic sale) {
    return DraftSaleCard(
      sale: sale,
      onEdit: () => _openEditDialog(sale),
      onDelete: () => _confirmDelete(sale['id']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Davom etayotgan savdolar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadDraftSales();
                await _loadDebtors();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Qarzdor mijozlar
                  if (_debtors.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Qarzdor mijozlar',
                        icon: Icons.person_outline,
                        color: Colors.red,
                        count: _debtors.length),
                    const SizedBox(height: 8),
                    ..._debtors.map((debtor) => DebtorCard(
                          debtor: debtor,
                          onPaymentTap: () => _showDebtorPayment(debtor),
                          onHistoryTap: () => _showPaymentHistory(debtor),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Davom etayotgan savdolar (Draft)
                  if (_draftSales.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Davom etayotgan',
                        icon: Icons.edit_note,
                        color: Colors.orange,
                        count: _draftSales.length),
                    const SizedBox(height: 8),
                    ..._draftSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Qarz savdolar (Debt)
                  if (_debtSales.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Qarz savdolar',
                        icon: Icons.money_off,
                        color: Colors.red,
                        count: _debtSales.length),
                    const SizedBox(height: 8),
                    ..._debtSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                  ],

                  // To'langan savdolar (Paid)
                  if (_paidSales.isNotEmpty) ...[
                    SectionHeader(
                        title: 'To\'langan savdolar',
                        icon: Icons.assignment_turned_in,
                        color: Colors.green,
                        count: _paidSales.length),
                    const SizedBox(height: 8),
                    ..._paidSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                  ],

                  // Bo'sh holat
                  if (_draftSales.isEmpty &&
                      _debtSales.isEmpty &&
                      _paidSales.isEmpty &&
                      _debtors.isEmpty)
                    const EmptyState(),
                ],
              ),
            ),
    );
  }

  void _showDebtorPayment(dynamic debtor) {
    showDialog(
      context: context,
      builder: (dialogContext) => DebtorPaymentDialog(
        debtor: debtor,
        debtSales: _debtSales,
        onPaymentSuccess: () {
          _loadDraftSales();
          _loadDebtors();
        },
      ),
    );
  }

  void _showPaymentHistory(dynamic debtor) async {
    await _loadDraftSales();
    final customerId = debtor['customerId'];
    final debtorSales =
        _debtSales.where((sale) => sale['customerId'] == customerId).toList();

    if (debtorSales.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qarz savdolari topilmadi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => PaymentHistoryDialog(
        customerName: debtor['customerName'] ?? 'Mijozsiz',
        debtorSales: debtorSales,
      ),
    );
  }
}
<<<<<<< robiya
=======

// Payment Dialog for Continue Sale
class _ContinuePaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;

  const _ContinuePaymentDialog({
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
  });

  @override
  State<_ContinuePaymentDialog> createState() => _ContinuePaymentDialogState();
}

class _ContinuePaymentDialogState extends State<_ContinuePaymentDialog> {
  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useClick = false;
  bool _useDebt = false;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _transferController = TextEditingController();
  final TextEditingController _clickController = TextEditingController();

  bool _isProcessing = false;

  double get _totalPaid {
    double total = 0;
    if (_useCash) total += double.tryParse(_cashController.text) ?? 0;
    if (_useTerminal) total += double.tryParse(_terminalController.text) ?? 0;
    if (_useTransfer) total += double.tryParse(_transferController.text) ?? 0;
    if (_useClick) total += double.tryParse(_clickController.text) ?? 0;
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _totalPaid;

  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  bool _canConfirm() {
    if (_hasDebt) {
      return widget.selectedCustomer != null && _totalPaid >= 0;
    } else {
      return _remainingAmount <= 0.01 ||
          (_remainingAmount > 0.01 && _totalPaid > 0);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _terminalController.dispose();
    _transferController.dispose();
    _clickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('To\'lov usullari'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Naqd
            CheckboxListTile(
              title: const Text('Naqd'),
              value: _useCash,
              onChanged: (value) {
                setState(() {
                  _useCash = value ?? false;
                  if (!_useCash) _cashController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useCash)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Naqd summa (so\'m)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Terminal
            CheckboxListTile(
              title: const Text('Plastik karta'),
              value: _useTerminal,
              onChanged: (value) {
                setState(() {
                  _useTerminal = value ?? false;
                  if (!_useTerminal) _terminalController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useTerminal)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _terminalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Plastik summa (so\'m)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Transfer
            CheckboxListTile(
              title: const Text('Hisob raqam'),
              value: _useTransfer,
              onChanged: (value) {
                setState(() {
                  _useTransfer = value ?? false;
                  if (!_useTransfer) _transferController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useTransfer)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _transferController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Transfer summa (so\'m)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Click
            CheckboxListTile(
              title: const Text('Click'),
              value: _useClick,
              onChanged: (value) {
                setState(() {
                  _useClick = value ?? false;
                  if (!_useClick) _clickController.clear();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useClick)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: TextField(
                  controller: _clickController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Click summa (so\'m)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Qarzga
            CheckboxListTile(
              title: const Text('Qarzga olish'),
              value: _useDebt,
              onChanged: (value) {
                if (widget.selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Qarzga olish uchun mijoz tanlang!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                setState(() {
                  _useDebt = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jami:'),
                      Text(NumberFormatter.formatDecimal(widget.totalAmount)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To\'langan:'),
                      Text(
                        NumberFormatter.formatDecimal(_totalPaid),
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_hasDebt ? 'Qarzga:' : 'Qolgan:'),
                      Text(
                        NumberFormatter.formatDecimal(_remainingAmount),
                        style: TextStyle(
                          color: _hasDebt ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || !_canConfirm()
              ? null
              : () async {
                  setState(() {
                    _isProcessing = true;
                  });

                  List<Map<String, dynamic>> payments = [];

                  if (_useCash && (_cashController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Cash',
                      'amount': double.tryParse(_cashController.text) ?? 0,
                    });
                  }

                  if (_useTerminal && (_terminalController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Terminal',
                      'amount': double.tryParse(_terminalController.text) ?? 0,
                    });
                  }

                  if (_useTransfer && (_transferController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Transfer',
                      'amount': double.tryParse(_transferController.text) ?? 0,
                    });
                  }

                  if (_useClick && (_clickController.text.isNotEmpty)) {
                    payments.add({
                      'paymentType': 'Click',
                      'amount': double.tryParse(_clickController.text) ?? 0,
                    });
                  }

                  try {
                    widget.onConfirm(payments, _hasDebt);
                  } catch (e) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                },
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_hasDebt ? 'Qarzga olish' : 'Tasdiqlash'),
        ),
      ],
    );
  }
}


class _PriceInputDialog extends StatefulWidget {
  final double currentPrice;
  final String productName;

  const _PriceInputDialog({
    Key? key,
    required this.currentPrice,
    required this.productName,
  }) : super(key: key);

  @override
  State<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<_PriceInputDialog> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.currentPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productName),
      content: TextField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Yangi narx (so\'m)',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: () {
            final price = double.tryParse(_priceController.text);
            if (price != null && price > 0) {
              Navigator.pop(context, price);
            }
          },
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}

class ReturnQuantityDialog extends StatefulWidget {
  final double maxQuantity;
  final String productName;

  const ReturnQuantityDialog({
    Key? key,
    required this.maxQuantity,
    required this.productName,
  }) : super(key: key);

  @override
  State<ReturnQuantityDialog> createState() => _ReturnQuantityDialogState();
}

class _ReturnQuantityDialogState extends State<ReturnQuantityDialog> {
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Qaytarish'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.productName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Maksimal: ${widget.maxQuantity}'),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Qaytariladigan miqdor',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: () {
            final qty = double.tryParse(_quantityController.text);
            if (qty != null && qty > 0 && qty <= widget.maxQuantity) {
              Navigator.pop(context, qty);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Noto\'g\'ri miqdor kiritildi')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Qaytarish'),
        ),
      ],
    );
  }
}

class DraftSaleCard extends StatelessWidget {
  final dynamic sale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DraftSaleCard({
    Key? key,
    required this.sale,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customerName = sale['customerName'] ?? 'Noma\'lum mijoz';

    // To'g'ri hisoblash: Har bir item ning quantity sini qo'shib chiqish
    double itemsCount = 0;
    if (sale['items'] != null && sale['items'] is List) {
      for (var item in sale['items']) {
        itemsCount += (item['quantity'] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      itemsCount = (sale['itemsCount'] as num?)?.toDouble() ?? 0.0;
    }

    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final date = DateTime.tryParse(sale['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormatter.formatQuantity(itemsCount)} ta mahsulot',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${NumberFormatter.formatDecimal(totalAmount)} so\'m',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text('O\'chirish',
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Davom etish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
>>>>>>> master
