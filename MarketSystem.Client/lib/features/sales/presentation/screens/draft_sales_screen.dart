import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/sales_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/customer_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';

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
    // Screen focus qaytganda refresh qilish
    if (mounted) {
      print(
          '🔄 DraftSalesScreen: didChangeDependencies called, refreshing sales and debtors...');
      Future.delayed(Duration.zero, () {
        _loadDraftSales();
        _loadDebtors();
      });
    }
  }

  Future<void> _loadDraftSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      final unfinished = await salesService.getMyUnfinishedSales();

      setState(() {
        _unfinishedSales = unfinished;
        _isLoading = false;
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

  Future<void> _loadDebtors() async {
    print('📥 DraftSalesScreen: _loadDebtors called...');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      final debtors = await salesService.getDebtors();
      print('✅ DraftSalesScreen: Loaded ${debtors.length} debtors');

      if (mounted) {
        setState(() {
          _debtors = debtors;
        });
      }
    } catch (e) {
      print('❌ DraftSalesScreen: Error loading debtors: $e');
    }
  }

  Future<void> _continueSale(dynamic draftSale) async {
    final saleId = draftSale['id'];

    // Draft savdoni yangi sale screen ochamiz
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContinueSaleScreen(saleId: saleId),
        ),
      );

      // Savdo tugatildi bo'lsa, listni yangilash
      if (result == true) {
        _loadDraftSales();
      }
    }
  }

  void _showDeleteConfirmation(String saleId) {
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
                print('=== DELETE SALE CLICKED ===');
                print('Sale ID: $saleId');

                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final salesService = SalesService(authProvider: authProvider);
                await salesService.deleteSale(saleId: saleId);

                print('Sale deleted successfully');

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
                print('Error deleting sale: $e');
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

  void _showCustomerSelectionDialog(String saleId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerService = CustomerService(authProvider: authProvider);

    try {
      // Load customers
      final customersData = await customerService.getAllCustomers();

      if (!mounted) return;

      // Show customer selection dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mijoz tanlang'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: customersData.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Mijozlar topilmadi',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: customersData.length,
                    itemBuilder: (context, index) {
                      final customer = customersData[index];
                      final customerName = customer['fullName'] ?? 'Noma\'lum';
                      final customerPhone = customer['phone'] ?? '';
                      final customerId = customer['id']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child:
                                Icon(Icons.person, color: Colors.blue.shade700),
                          ),
                          title: Text(customerName),
                          subtitle: Text(customerPhone),
                          onTap: () async {
                            // Close dialog
                            Navigator.pop(dialogContext);

                            // Update sale with selected customer
                            try {
                              final salesService =
                                  SalesService(authProvider: authProvider);
                              await salesService.updateSaleCustomer(
                                saleId: saleId,
                                customerId: customerId,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '✅ Mijoz qo\'shildi: $customerName'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Reload sales
                                _loadDraftSales();
                              }
                            } catch (e) {
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
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            // Mijozni olib tashlash tugmasi
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Mijozni olib tashlash (customerId ni null qilish)
                try {
                  final salesService = SalesService(authProvider: authProvider);
                  await salesService.updateSaleCustomer(
                    saleId: saleId,
                    customerId: null, // null = mijozni olib tashlash
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Mijoz olib tashlandi'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _loadDraftSales();
                  }
                } catch (e) {
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
              child: const Text('Mijozni olib tashlash',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mijozlarni yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    _buildSectionHeader(
                        'Qarzdor mijozlar', Icons.person_outline, Colors.red),
                    const SizedBox(height: 8),
                    ..._debtors.map((debtor) => _buildDebtorCard(debtor)),
                    const SizedBox(height: 16),
                  ],

                  // Davom etayotgan savdolar (Draft)
                  if (_draftSales.isNotEmpty) ...[
                    _buildSectionHeader(
                        'Davom etayotgan', Icons.edit_note, Colors.orange),
                    const SizedBox(height: 8),
                    ..._draftSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _openEditDialog(
                              sale), // Tahrirlash logikasi mainda qoladi
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Qarz savdolar (Debt)
                  if (_debtSales.isNotEmpty) ...[
                    _buildSectionHeader(
                        'Qarz savdolar', Icons.money_off, Colors.red),
                    const SizedBox(height: 8),
                    ..._debtSales.map((sale) => _buildDraftSaleCard(sale)),
                  ],

                  // To'langan savdolar (Paid) - vozvrat uchun
                  if (_paidSales.isNotEmpty) ...[
                    _buildSectionHeader('To\'langan savdolar',
                        Icons.assignment_turned_in, Colors.green),
                    const SizedBox(height: 8),
                    ..._paidSales.map((sale) => _buildDraftSaleCard(sale)),
                  ],

                  // Ikkalasi ham bo'sh
                  if (_draftSales.isEmpty &&
                      _debtSales.isEmpty &&
                      _paidSales.isEmpty &&
                      _debtors.isEmpty)
                    _buildEmptyState(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final count = title == 'Davom etayotgan'
        ? _draftSales.length
        : title == 'Qarz savdolar'
            ? _debtSales.length
            : title == 'Qarzdor mijozlar'
                ? _debtors.length
                : _paidSales.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtorCard(dynamic debtor) {
    final customerName = debtor['customerName'] ?? 'Mijozsiz';
    final customerPhone = debtor['customerPhone'];
    final totalDebt = (debtor['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final customerId = debtor['customerId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.4),
          width: 2,
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
          // Header: Customer info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (customerPhone != null)
                      Text(
                        customerPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Qarz miqdori
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Qarz miqdori:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  NumberFormatter.formatDecimal(remainingDebt),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tugmalar: To'lov tarixi va To'lash
          Row(
            children: [
              // To'lov tarixi tugmasi
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentHistory(debtor),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Tarix'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // To'lash tugmasi
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDebtorPaymentDialog(debtor),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('To\'lash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDebtorPaymentDialog(dynamic debtor) {
    final customerName = debtor['customerName'] ?? 'Mijozsiz';
    final remainingDebt = (debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;

    final amountController =
        TextEditingController(text: remainingDebt.toString());
    bool selectedCash = false;
    bool selectedTerminal = false;
    bool selectedTransfer = false;
    bool selectedClick = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('To\'lash: $customerName'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Qarz miqdori
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Qarz:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        NumberFormatter.formatDecimal(remainingDebt),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // To'lov miqdori
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'To\'lov miqdori',
                    prefixText: 'so\'m ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // To'lov usuli
                const Text('To\'lov usuli:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Naqd'),
                  value: selectedCash,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCash = value ?? false;
                      if (selectedCash) {
                        selectedTerminal = false;
                        selectedTransfer = false;
                        selectedClick = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Plastik karta'),
                  value: selectedTerminal,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTerminal = value ?? false;
                      if (selectedTerminal) {
                        selectedCash = false;
                        selectedTransfer = false;
                        selectedClick = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Hisob raqam'),
                  value: selectedTransfer,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTransfer = value ?? false;
                      if (selectedTransfer) {
                        selectedCash = false;
                        selectedTerminal = false;
                        selectedClick = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Click'),
                  value: selectedClick,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClick = value ?? false;
                      if (selectedClick) {
                        selectedCash = false;
                        selectedTerminal = false;
                        selectedTransfer = false;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iltimos, to\'g\'ri miqdor kiriting'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                String paymentType = '';
                if (selectedCash)
                  paymentType = 'Cash';
                else if (selectedTerminal)
                  paymentType = 'Terminal';
                else if (selectedTransfer)
                  paymentType = 'Transfer';
                else if (selectedClick)
                  paymentType = 'Click';
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iltimos, to\'lov usulini tanlang'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final salesService = SalesService(authProvider: authProvider);

                  // Get debtor's customer ID and find their debt sales
                  final customerId = debtor['customerId'];
                  final debtorSales = _debtSales
                      .where((sale) => sale['customerId'] == customerId)
                      .toList();

                  if (debtorSales.isEmpty) {
                    throw Exception('Qarz savdolari topilmadi');
                  }

                  // Use the oldest debt sale
                  final saleId = debtorSales[0]['id'];

                  await salesService.addPayment(
                    saleId: saleId,
                    paymentType: paymentType,
                    amount: amount,
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✅ To\'lov muvaffaqiyatli amalga oshirildi: ${NumberFormatter.formatDecimal(amount)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh lists
                    _loadDraftSales();
                    _loadDebtors();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(dialogContext);
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('To\'lash'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory(dynamic debtor) async {
    final customerName = debtor['customerName'] ?? 'Mijozsiz';
    final customerId = debtor['customerId'];

    // Refresh data first to get latest payments
    await _loadDraftSales();

    // Get debtor's debt sales
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
      builder: (context) => AlertDialog(
        title: Text('To\'lov tarixi: $customerName'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: debtorSales.length,
            itemBuilder: (context, index) {
              final sale = debtorSales[index];
              final payments = sale['payments'] as List<dynamic>? ?? [];
              final saleTotal =
                  (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
              final salePaid = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
              final saleRemaining =
                  (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;
              final saleDate = sale['createdAt'];

              // Format date
              String formattedDate = 'Noma\'lum';
              if (saleDate != null) {
                try {
                  final date = DateTime.parse(saleDate);
                  formattedDate = '${date.day}.${date.month}.${date.year}';
                } catch (e) {
                  formattedDate = saleDate.toString();
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title:
                      Text('Savdo #${sale['id'].toString().substring(0, 8)}'),
                  subtitle: Text(
                      '$formattedDate • Jami: ${NumberFormatter.formatDecimal(saleTotal)}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Savdo summary
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Jami summa:'),
                                    Text(NumberFormatter.formatDecimal(
                                        saleTotal)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('To\'langan:',
                                        style: TextStyle(color: Colors.green)),
                                    Text(
                                      NumberFormatter.formatDecimal(salePaid),
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Qolgan qarz:',
                                        style: TextStyle(color: Colors.red)),
                                    Text(
                                      NumberFormatter.formatDecimal(
                                          saleRemaining),
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // To'lovlar ro'yxati
                          if (payments.isEmpty)
                            const Text('To\'lovlar yo\'q',
                                style: TextStyle(color: Colors.grey))
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('To\'lovlar:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                ...payments.map<Widget>((payment) {
                                  final amount =
                                      (payment['amount'] as num?)?.toDouble() ??
                                          0.0;
                                  var paymentTypeRaw = payment['paymentType'];

                                  // Debug - to show what we're getting
                                  print('=== PAYMENT DEBUG ===');
                                  print('Full payment object: $payment');
                                  print(
                                      'paymentType raw type: ${paymentTypeRaw.runtimeType}');
                                  print('paymentType value: $paymentTypeRaw');

                                  // Handle different types of paymentType
                                  String paymentType;
                                  if (paymentTypeRaw == null) {
                                    paymentType = 'Noma\'lum';
                                  } else if (paymentTypeRaw is String) {
                                    paymentType = paymentTypeRaw.toString();
                                  } else {
                                    paymentType = paymentTypeRaw.toString();
                                  }

                                  final paymentDate = payment['createdAt'];

                                  String formattedPaymentDate = '';
                                  if (paymentDate != null) {
                                    try {
                                      final date = DateTime.parse(paymentDate);
                                      formattedPaymentDate =
                                          '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                                    } catch (e) {
                                      formattedPaymentDate = '';
                                    }
                                  }

                                  // Payment type icon and display text
                                  IconData getPaymentIcon() {
                                    final type =
                                        paymentType.toLowerCase().trim();
                                    print('Getting icon for type: "$type"');
                                    if (type == 'cash' || type.contains('naqd'))
                                      return Icons.money;
                                    if (type == 'terminal' ||
                                        type.contains('plastik') ||
                                        type.contains('karta'))
                                      return Icons.credit_card;
                                    if (type == 'transfer' ||
                                        type.contains('hisob'))
                                      return Icons.account_balance;
                                    if (type == 'click') return Icons.touch_app;
                                    return Icons.payment;
                                  }

                                  String getPaymentTypeDisplay() {
                                    final type =
                                        paymentType.toLowerCase().trim();
                                    if (type == 'cash' || type.contains('naqd'))
                                      return 'Naqd';
                                    if (type == 'terminal' ||
                                        type.contains('plastik') ||
                                        type.contains('karta'))
                                      return 'Plastik karta';
                                    if (type == 'transfer' ||
                                        type.contains('hisob'))
                                      return 'Hisob raqam';
                                    if (type == 'click') return 'Click';
                                    return paymentType; // Show original if no match
                                  }

                                  return Card(
                                    elevation: 0,
                                    color: Colors.green.shade50,
                                    child: ListTile(
                                      leading: Icon(getPaymentIcon(),
                                          color: Colors.green),
                                      title: Text(
                                        NumberFormatter.formatDecimal(amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${getPaymentTypeDisplay()}${formattedPaymentDate.isNotEmpty ? ' • $formattedPaymentDate' : ''}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Davom etayotgan savdolar yo\'q',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Boshlang\'ich savdolar bu yerda ko\'rsatiladi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draft savdoni davom ettirish screeni
class ContinueSaleScreen extends StatefulWidget {
  final String saleId;

  const ContinueSaleScreen({super.key, required this.saleId});

  @override
  State<ContinueSaleScreen> createState() => _ContinueSaleScreenState();
}

class _ContinueSaleScreenState extends State<ContinueSaleScreen> {
  Map<String, dynamic>? _sale;
  List<Map<String, dynamic>> _cartItems = [];
  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _isLoading = true;

  // Search & Filter
  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    // _loadData() ni async chaqiramiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final name = (product['name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  double get _totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item['salePrice'] is num
          ? (item['salePrice'] as num).toDouble()
          : double.tryParse(item['salePrice']?.toString() ?? '') ?? 0.0;
      final qty = item['quantity'] is num
          ? (item['quantity'] as num).toDouble() // ✅ DECIMAL
          : double.tryParse(item['quantity']?.toString() ?? '') ??
              0.0; // ✅ DECIMAL
      return sum + (price * qty);
    });
  }

  Future<void> _loadData() async {
    print('📥 === _loadData START ===');
    print('Sale ID: ${widget.saleId}');

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final productService = ProductService(authProvider: authProvider);

      print('📤 Fetching sale data...');
      final sale = await salesService.getSaleById(widget.saleId);

      print('📤 Fetching products...');
      final products = await productService.getAllProducts();

      // Mavjud sale items ni cart ga yuklash
      final items = sale['items'] as List<dynamic>? ?? [];
      print('📦 Sale items count: ${items.length}');

      final cartItems = items.map((item) {
        return {
          'saleItemId': item['id'],
          'productId': item['productId'],
          'productName': item['productName'],
          'salePrice': (item['salePrice'] as num?)?.toDouble() ?? 0.0,
          'minSalePrice': (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          'costPrice': (item['costPrice'] as num?)?.toDouble() ?? 0.0,
          'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
          'comment': item['comment'] ?? '',
        };
      }).toList();

      print('✅ Data fetched successfully!');
      print('📊 Cart items: ${cartItems.length}');

      setState(() {
        _sale = sale;
        _products = products;
        _filteredProducts = products;
        _cartItems = cartItems;
        _selectedCustomer = sale['customerName'] != null
            ? {
                'id': sale['customerId'],
                'fullName': sale['customerName'],
              }
            : null;
        _isLoading = false;
      });

      print('✅ setState complete!');
    } catch (e) {
      print('❌ ERROR in _loadData: $e');
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
        Navigator.pop(context);
      }
    }
    print('📥 === _loadData END ===');
  }

  Future<void> _addToCart(dynamic product) async {
    print('🛒 === _addToCart START ===');
    print('Product: ${product['name']}');
    print('Sale ID: ${widget.saleId}');

    // ⚡ OPTIMISTIK UI - Yangi mahsulotni cartga qo'shamiz
    final newItem = {
      'productId': product['id'],
      'productName': product['name'],
      'salePrice': product['salePrice'] ?? 0.0,
      'minSalePrice': (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
      'costPrice': (product['costPrice'] as num?)?.toDouble() ?? 0.0,
      'quantity': 1,
      'comment': '',
      // saleItemId yo'q - hali backendda yo'q
    };

    print('⚡ Optimistic UI: Adding to cart locally');
    if (!mounted) return;
    setState(() {
      _cartItems.add(newItem);
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      print('📤 Calling addSaleItem...');

      // Backendga 1 ta mahsulot qo'shamiz
      // Backend avtomatik ravishda mavjud itemni topib quantity oshiradi
      await salesService.addSaleItem(
        saleId: widget.saleId,
        productId: product['id'],
        quantity: 1,
        salePrice: product['salePrice'] ?? 0.0,
        minSalePrice: (product['minSalePrice'] as num?)?.toDouble() ?? 0.0,
        comment: '',
      );

      print('✅ addSaleItem success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${product['name']} savatga qo\'shildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, data ni qayta yuklash
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🛒 === _addToCart END ===');
  }

  Future<void> _removeFromCart(int index) async {
    final item = _cartItems[index];

    print('🗑️ === _removeFromCart START ===');
    print('Index: $index');
    print('Product: ${item['productName']}');
    print('SaleItemId: ${item['saleItemId']}');
    print('Quantity: ${item['quantity']}');

    // Itemni backup qilamiz (xatolik bo'lsa, qayta qo'shish uchun)
    final backupItem = Map<String, dynamic>.from(item);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      print('📤 Calling removeSaleItem...');

      // Backenddan o'chiramiz
      await salesService.removeSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: (item['quantity'] as num?)?.toDouble() ??
            0.0, // ✅ DECIMAL - Butunlay o'chirish
      );

      print('✅ removeSaleItem success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mahsulot olib tashlandi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, itemni qayta qo'shamiz
      if (!mounted) return;
      setState(() {
        _cartItems.insert(index, backupItem);
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
    print('🗑️ === _removeFromCart END ===');
  }

  Future<void> _updateQuantity(int index, double newQuantity) async {
    // ✅ DECIMAL
    final item = _cartItems[index];

    print('🔢 === _updateQuantity START ===');
    print('Index: $index');
    print('Product: ${item['productName']}');
    print('Current: ${item['quantity']} → New: $newQuantity');

    if (newQuantity <= 0) {
      print('⚠️ Quantity <= 0, removing...');
      await _removeFromCart(index);
      return;
    }

    final currentQuantity =
        (item['quantity'] as num?)?.toDouble() ?? 0.0; // ✅ DECIMAL

    // quantityDiff == 0 bo'lsa, hech narsa qilmaymiz (quantity o'zgarmagan)
    if (newQuantity == currentQuantity) {
      print('⚠️ Quantity unchanged, skipping');
      return;
    }

    final quantityDiff = newQuantity - currentQuantity;
    print('Diff: $quantityDiff');

    // ⚡ OPTIMISTIK UI YANGILASH - Darhol UI ni yangilaymiz!
    if (item.containsKey('saleItemId')) {
      print('⚡ Optimistic UI update: ${item['quantity']} → $newQuantity');
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      if (quantityDiff > 0) {
        print('📤 INCREASING by $quantityDiff');
        // Quantity oshirish - backendga yangi item qo'shamiz
        await salesService.addSaleItem(
          saleId: widget.saleId,
          productId: item['productId'],
          quantity: quantityDiff, // ✅ DECIMAL
          salePrice: item['salePrice'],
          minSalePrice: (item['minSalePrice'] as num?)?.toDouble() ?? 0.0,
          comment: item['comment'] ?? '',
        );
      } else {
        print('📤 DECREASING by ${quantityDiff.abs()}');
        // Quantity kamaytirish - backenddan removeSaleItem orqali kamaytiramiz
        final quantityToRemove = quantityDiff.abs(); // ✅ DECIMAL
        await salesService.removeSaleItem(
          saleId: widget.saleId,
          saleItemId: item['saleItemId'],
          quantity: quantityToRemove, // ✅ DECIMAL
        );
      }

      print('✅ API call success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, data ni qayta yuklash
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🔢 === _updateQuantity END ===');
  }

  Future<void> _updateItemPrice(int index) async {
    final item = _cartItems[index];
    final currentPrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;

    // Narx kiritish dialogi
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _PriceInputDialog(
        currentPrice: currentPrice,
        productName: item['productName'],
      ),
    );

    if (!mounted) return;

    if (result != null && result != currentPrice) {
      // Narxni o'zgartirish
      if (item.containsKey('saleItemId')) {
        try {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final salesService = SalesService(authProvider: authProvider);

          await salesService.updateSaleItemPrice(
            saleItemId: item['saleItemId'],
            newPrice: result,
            comment: 'Narx yangilandi (Draft savdo)',
          );

          // Reload data
          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Narx yangilandi: ${NumberFormatter.format(result)}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
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
    }
  }

  void _showPaymentDialog() {
    final totalAmount = (_sale!['totalAmount'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ContinuePaymentDialog(
        saleId: widget.saleId,
        totalAmount: totalAmount,
        selectedCustomer: _selectedCustomer,
        onConfirm: (payments, useDebt) async {
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final salesService = SalesService(authProvider: authProvider);

            for (var payment in payments) {
              await salesService.addPayment(
                saleId: widget.saleId,
                paymentType: payment['paymentType'],
                amount: payment['amount'],
              );
            }

            if (mounted) {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context, true); // Close sale screen with success
            }
          } catch (e) {
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
      ),
    );
  }

  Future<void> _returnItem(int index) async {
    final item = _cartItems[index];
    final currentQuantity =
        (item['quantity'] as num?)?.toDouble() ?? 0.0; // ✅ DECIMAL

    print('↩️ === _returnItem START ===');
    print('Index: $index');
    print('Product: ${item['productName']}');
    print('Current Quantity: $currentQuantity');

    if (currentQuantity <= 0) {
      print('⚠️ Quantity is 0, cannot return');
      return;
    }

    // Qancha qaytarishni so'rash
    final returnQuantity = await showDialog<double>(
      // ✅ DECIMAL
      context: context,
      builder: (context) => ReturnQuantityDialog(
        productName: item['productName'],
        maxQuantity: currentQuantity, // ✅ DECIMAL
      ),
    );

    if (returnQuantity == null || returnQuantity <= 0) {
      print('⚠️ Return cancelled or invalid quantity');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      print('📤 Calling returnSaleItem...');
      print('Sale Item ID: ${item['saleItemId']}');
      print('Return Quantity: $returnQuantity');

      await salesService.returnSaleItem(
        saleId: widget.saleId,
        saleItemId: item['saleItemId'],
        quantity: returnQuantity.toDouble(),
      );

      print('✅ returnSaleItem success!');
      print('📥 Loading data...');

      // Backenddan yangi ma'lumotni yuklash
      await _loadData();

      print('✅ Data loaded! Cart items: ${_cartItems.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${returnQuantity} ta ${item['productName']} qaytarildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      // Xatolik bo'lsa, data ni qayta yuklash
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('↩️ === _returnItem END ===');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Savdo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Savdo')),
        body: const Center(child: Text('Savdo topilmadi')),
      );
    }

    final customerName = _sale!['customerName'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Draft Savdo'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Customer info
          if (customerName != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Cart items
          if (_cartItems.isNotEmpty)
            Container(
              height: 104,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
                  final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                  final itemTotal = price * qty;
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['productName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['quantity']} x ${NumberFormatter.format(item['salePrice'])}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              NumberFormatter.formatDecimal(itemTotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _updateItemPrice(index),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Agar savdo yopilgan (Closed) bo'lsa, vozvrat tugmasi
                            if (_sale?['status'] == 'Closed')
                              GestureDetector(
                                onTap: () => _returnItem(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.orange.shade300,
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.assignment_return,
                                          size: 14,
                                          color: Colors.orange.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qaytarish',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final currentQty =
                                          (item['quantity'] as num?)?.toInt() ??
                                              0;
                                      await _updateQuantity(
                                          index, currentQty - 1);
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.remove,
                                          size: 14, color: Color(0xFF374151)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final currentQty =
                                          (item['quantity'] as num?)?.toInt() ??
                                              0;
                                      await _updateQuantity(
                                          index, currentQty + 1);
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.add,
                                          size: 14, color: Color(0xFF374151)),
                                    ),
                                  ),
                                ],
                              ),
                            if (_sale?['status'] != 'Closed')
                              GestureDetector(
                                onTap: () async {
                                  await _removeFromCart(index);
                                },
                                child: const Icon(Icons.close,
                                    size: 14, color: Color(0xFFEF4444)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Products section
          Expanded(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Mahsulot qidirish...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Color(0xFF9CA3AF)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProducts();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),

                // Products grid
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(
                          child: Text('Mahsulotlar topilmadi',
                              style: TextStyle(color: Color(0xFF9CA3AF))))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final quantity =
                                (product['quantity'] as num?)?.toDouble() ??
                                    0.0;
                            final isInStock = quantity > 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isInStock
                                      ? const Color(0xFFE5E7EB)
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Noma\'lum',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0xFF1F2937),
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormatter.format(
                                          product['salePrice']),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 10,
                                              color: quantity > 5
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$quantity',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: quantity > 5
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isInStock
                                                ? () async {
                                                    await _addToCart(product);
                                                  }
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isInStock
                                                    ? const Color(0xFF3B82F6)
                                                    : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.add,
                                                  size: 14,
                                                  color: isInStock
                                                      ? Colors.white
                                                      : Colors.grey.shade500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Total & Checkout button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              children: [
                // Total amount
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jami summa',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151)),
                      ),
                      Text(
                        NumberFormatter.formatDecimal(_totalAmount),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Faqat yopilmagan savdolar uchun to'lov tugmasi
                if (_sale?['status'] != 'Closed')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _cartItems.isEmpty ? null : _showPaymentDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cartItems.isEmpty
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('TO\'LOV QILISH',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3)),
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
    final itemsCount = sale['itemsCount'] ?? 0;
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
                  '$itemsCount ta mahsulot',
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
