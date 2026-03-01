import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/sales_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';
import 'debtor_detail_screen.dart';

/// Qarzdorlar Screeni
/// Debt statusdagi mijozlar ro'yxati
class DebtorsScreen extends StatefulWidget {
  const DebtorsScreen({super.key});

  @override
  State<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  List<dynamic> _debtors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebtors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Screen focus qaytganda refresh qilish
    if (mounted) {
      print(
          '🔄 DebtorsScreen: didChangeDependencies called, refreshing debtors...');
      Future.delayed(Duration.zero, () {
        _loadDebtors();
      });
    }
  }

  Future<void> _loadDebtors() async {
    print('📥 DebtorsScreen: _loadDebtors called...');
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      final debtors = await salesService.getDebtors();
      print('✅ DebtorsScreen: Loaded ${debtors.length} debtors');

      setState(() {
        _debtors = debtors;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DebtorsScreen: Error loading debtors: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Qarzdorlar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debtors.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDebtors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _debtors.length,
                    itemBuilder: (context, index) {
                      final debtor = _debtors[index];
                      return _buildDebtorCard(debtor);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Qarzdorlar yo\'q',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Qarzli mijozlar bu yerda ko\'rsatiladi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
    final paidAmount = (debtor['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final debtCount = debtor['debtCount'] ?? 0;
    final oldestDebtDate = debtor['oldestDebtDate'];

    // Format date with GMT+5 (Tashkent time)
    String formattedDate = '';
    if (oldestDebtDate != null) {
      try {
        final date = DateTime.parse(oldestDebtDate);
        // Convert both dates to GMT+5 for comparison
        final tashkentDate = date.toUtc().add(const Duration(hours: 5));
        final tashkentNow =
            DateTime.now().toUtc().add(const Duration(hours: 5));
        final difference = tashkentNow.difference(tashkentDate);

        if (difference.inDays == 0) {
          formattedDate = 'Bugun ${NumberFormatter.formatTime(oldestDebtDate)}';
        } else if (difference.inDays == 1) {
          formattedDate = 'Kecha ${NumberFormatter.formatTime(oldestDebtDate)}';
        } else if (difference.inDays < 30) {
          formattedDate =
              '${difference.inDays} kun oldin, ${NumberFormatter.formatTime(oldestDebtDate)}';
        } else if (difference.inDays < 365) {
          final months = (difference.inDays / 30).floor();
          formattedDate =
              '$months oy oldin, ${NumberFormatter.formatDateTime(oldestDebtDate, showTime: false)}';
        } else {
          final years = (difference.inDays / 365).floor();
          formattedDate =
              '$years yil oldin, ${NumberFormatter.formatDateTime(oldestDebtDate, showTime: false)}';
        }
      } catch (e) {
        formattedDate = '';
      }
    }

    // Qarz muddati bo'yicha rang
    Color getDebtAgeColor() {
      if (oldestDebtDate == null) return Colors.orange;

      try {
        final date = DateTime.parse(oldestDebtDate);
        // Convert both dates to GMT+5 for comparison
        final tashkentDate = date.toUtc().add(const Duration(hours: 5));
        final tashkentNow =
            DateTime.now().toUtc().add(const Duration(hours: 5));
        final difference = tashkentNow.difference(tashkentDate);

        if (difference.inDays <= 30) {
          return Colors.orange; // 1 oy gacha
        } else if (difference.inDays <= 90) {
          return Colors.deepOrange; // 3 oy gacha
        } else {
          return Colors.red; // 3 oydan ko'p
        }
      } catch (e) {
        return Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getDebtAgeColor().withValues(alpha: 0.3),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DebtorDetailScreen(
                  customerId: debtor['customerId'],
                  customerName: customerName,
                  debtorData: debtor,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Customer & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: getDebtAgeColor(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: getDebtAgeColor(),
                                  ),
                                ),
                                if (customerPhone != null)
                                  Text(
                                    customerPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (formattedDate.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getDebtAgeColor().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: getDebtAgeColor(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Debt info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jami qarz:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            NumberFormatter.formatDecimal(totalDebt),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: getDebtAgeColor(),
                            ),
                          ),
                        ],
                      ),
                      if (paidAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'To\'langan:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Text(
                              NumberFormatter.formatDecimal(paidAmount),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Qolgan qarz:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            NumberFormatter.formatDecimal(remainingDebt),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer: Debt count
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$debtCount ta savdo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: getDebtAgeColor(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
