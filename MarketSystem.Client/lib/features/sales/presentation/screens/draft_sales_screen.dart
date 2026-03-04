import 'package:flutter/material.dart';
import 'package:market_system_client/features/sales/presentation/screens/%20continue_sale_screen.dart';
import 'package:market_system_client/features/sales/presentation/widgets/debtor_payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/payment_history_dialog.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/features/sales/presentation/widgets/customer_selection_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/debtor_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/draft_sale_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/empty_state.dart';
import 'package:market_system_client/features/sales/presentation/widgets/section_header.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DraftSalesScreen extends StatefulWidget {
  const DraftSalesScreen({super.key});

  @override
  State<DraftSalesScreen> createState() => _DraftSalesScreenState();
}

class _DraftSalesScreenState extends State<DraftSalesScreen> {
  List<dynamic> _unfinishedSales = [];
  List<dynamic> _debtors = [];
  bool _isLoading = true;

  List<dynamic> get _draftSales =>
      _unfinishedSales.where((s) => s['status'] == 'Draft').toList();
  List<dynamic> get _debtSales =>
      _unfinishedSales.where((s) => s['status'] == 'Debt').toList();
  List<dynamic> get _paidSales =>
      _unfinishedSales.where((s) => s['status'] == 'Paid').toList();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) Future.delayed(Duration.zero, _loadAll);
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadDraftSales(), _loadDebtors()]);
  }

  Future<void> _loadDraftSales() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final unfinished = await salesService.getMyUnfinishedSales();
      if (mounted) setState(() => _unfinishedSales = unfinished);
    } catch (e) {
      if (mounted) _showSnack('Xatolik: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDebtors() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final debtors = await salesService.getDebtors();
      if (mounted) setState(() => _debtors = debtors);
    } catch (e) {
      debugPrint('Debtors load error: $e');
    }
  }

  Future<void> _continueSale(dynamic sale) async {
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContinueSaleScreen(saleId: sale['id'])),
    );
    if (result == true) _loadDraftSales();
  }

  void _confirmDelete(String saleId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Savdoni o'chirish",
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text("Haqiqatan ham bu savdoni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Bekor qilish', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final salesService = SalesService(authProvider: authProvider);
                await salesService.deleteSale(saleId: saleId);
                if (mounted) {
                  _showSnack("Savdo o'chirildi", isError: false);
                  _loadDraftSales();
                }
              } catch (e) {
                if (mounted)
                  _showSnack("O'chirishda xatolik: $e", isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(dynamic sale) {
    showDialog(
      context: context,
      builder: (_) => CustomerSelectionDialog(
        saleId: sale['id'],
        onCustomerSelected: _loadDraftSales,
      ),
    );
  }

  void _showDebtorPayment(dynamic debtor) {
    showDebtorPaymentSheet(
      context,
      debtor: debtor,
      debtSales: _debtSales,
      onPaymentSuccess: _loadAll,
    );
  }

  void _showPaymentHistory(dynamic debtor) async {
    await _loadDraftSales();
    final customerId = debtor['customerId'];
    final debtorSales =
        _debtSales.where((sale) => sale['customerId'] == customerId).toList();

    if (debtorSales.isEmpty) {
      _showSnack('Qarz savdolari topilmadi', isError: false);
      return;
    }

    if (!mounted) return;

    showPaymentHistorySheet(
      context,
      customerName: debtor['customerName'] ?? 'Mijozsiz',
      debtorSales: debtorSales,
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = _draftSales.isEmpty &&
        _debtSales.isEmpty &&
        _paidSales.isEmpty &&
        _debtors.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: l10n.draftSales,
        onRefresh: _loadAll,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (isEmpty) const EmptyState(),

                  // Qarzdor mijozlar
                  if (_debtors.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Qarzdor mijozlar',
                      icon: Icons.person_outline,
                      color: Colors.red,
                      count: _debtors.length,
                    ),
                    const SizedBox(height: 12),
                    ..._debtors.map((debtor) => DebtorCard(
                          debtor: debtor,
                          onPaymentTap: () => _showDebtorPayment(debtor),
                          onHistoryTap: () => _showPaymentHistory(debtor),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Draft savdolar
                  if (_draftSales.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Davom etayotgan',
                      icon: Icons.edit_note_rounded,
                      color: Colors.orange,
                      count: _draftSales.length,
                    ),
                    const SizedBox(height: 12),
                    ..._draftSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _continueSale(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Qarz savdolar
                  if (_debtSales.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Qarz savdolar',
                      icon: Icons.money_off_rounded,
                      color: Colors.red,
                      count: _debtSales.length,
                    ),
                    const SizedBox(height: 12),
                    ..._debtSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _continueSale(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // To'langan savdolar
                  if (_paidSales.isNotEmpty) ...[
                    SectionHeader(
                      title: "To'langan savdolar",
                      icon: Icons.assignment_turned_in_outlined,
                      color: Colors.green,
                      count: _paidSales.length,
                    ),
                    const SizedBox(height: 12),
                    ..._paidSales.map((sale) => DraftSaleCard(
                          sale: sale,
                          onEdit: () => _continueSale(sale),
                          onDelete: () => _confirmDelete(sale['id']),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}
