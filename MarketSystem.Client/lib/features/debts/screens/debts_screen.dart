import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/debt_service.dart';
import '../../../core/providers/auth_provider.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<dynamic> _debts = [];
  Map<String, String> _customerNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtService = DebtService(authProvider: authProvider);

      final debts = await debtService.getAllDebts(status: 'Open');

      // Load customer names
      final Map<String, String> names = {};
      for (var debt in debts) {
        if (!names.containsKey(debt['customerId'])) {
          names[debt['customerId']] = debt['customerName'] ?? 'Noma\'lum';
        }
      }

      setState(() {
        _debts = debts;
        _customerNames = names;
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

  Future<void> _showPayDebtDialog(dynamic debt) async {
    final TextEditingController amountController = TextEditingController(
      text: debt['remainingDebt'].toString(),
    );
    String selectedPaymentType = 'Cash';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Qarzni to\'lash'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mijoz: ${_customerNames[debt['customerId']] ?? 'Noma\'lum'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Qolgan qarz: ${debt['remainingDebt']} so\'m',
                  style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'To\'lov summa',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('To\'lov turi:', style: TextStyle(fontWeight: FontWeight.w600)),
                RadioListTile<String>(
                  title: const Text('Naqd (Cash)'),
                  value: 'Cash',
                  groupValue: selectedPaymentType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPaymentType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Plastik karta (Terminal)'),
                  value: 'Terminal',
                  groupValue: selectedPaymentType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPaymentType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Hisob raqam (Transfer)'),
                  value: 'Transfer',
                  groupValue: selectedPaymentType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPaymentType = value!;
                    });
                  },
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
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iltimos, to\'g\'ri summa kiriting'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final debtService = DebtService(authProvider: authProvider);
                  await debtService.payDebt(
                    debtId: debt['id'],
                    paymentType: selectedPaymentType,
                    amount: amount,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ To\'lov muvaffaqiyatli amalga oshirildi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadData();
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
              child: const Text('To\'lash'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Qarzdorlik', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 16),
                      Text(
                        'Qarzdorliklar yo\'q',
                        style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _debts.length,
                    itemBuilder: (context, index) {
                      final debt = _debts[index];
                      final customerName = _customerNames[debt['customerId']] ?? 'Noma\'lum';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 20, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: debt['status'] == 'Open' ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      debt['status'] == 'Open' ? 'Ochiq' : 'Yopiq',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: debt['status'] == 'Open' ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jami qarz:',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                      ),
                                      Text(
                                        '${debt['totalDebt']} so\'m',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Qolgan qarz:',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                      ),
                                      Text(
                                        '${debt['remainingDebt']} so\'m',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (debt['status'] == 'Open')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showPayDebtDialog(debt),
                                    icon: const Icon(Icons.payment, size: 18),
                                    label: const Text('To\'lash'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
