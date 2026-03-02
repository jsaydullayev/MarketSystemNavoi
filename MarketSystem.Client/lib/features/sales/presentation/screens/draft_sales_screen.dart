import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
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