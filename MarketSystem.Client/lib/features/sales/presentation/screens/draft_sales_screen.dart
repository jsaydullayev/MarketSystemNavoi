import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/features/sales/presentation/screens/%20continue_sale_screen.dart';
import 'package:market_system_client/features/sales/presentation/widgets/debtor_payment_dialog.dart';
import 'package:market_system_client/features/sales/presentation/widgets/payment_history_dialog.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continuing_sale_row.dart';
import 'package:market_system_client/features/sales/presentation/widgets/davom_segmented_control.dart';
import 'package:market_system_client/features/sales/presentation/widgets/debtor_card.dart';
import 'package:market_system_client/features/sales/presentation/widgets/empty_state.dart';
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

  /// Default tab — the screen exists primarily so a seller can pick up a
  /// paused Draft after handling a quick walk-in sale.
  DavomTab _tab = DavomTab.davom;

  List<dynamic> get _draftSales =>
      _unfinishedSales.where((s) => s['status'] == 'Draft').toList();
  List<dynamic> get _debtSales =>
      _unfinishedSales.where((s) => s['status'] == 'Debt').toList();
  // "Paid" tab also surfaces Closed (debt-paid-off) — both are terminal-paid.
  List<dynamic> get _paidSales => _unfinishedSales.where((s) {
        final st = (s['status'] as String?) ?? '';
        return st == 'Paid' || st == 'Closed';
      }).toList();

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
      final l10n = AppLocalizations.of(context)!;
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
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
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteSale,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l10n.deleteSaleConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey[600])),
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
                  _showSnack(l10n.saleDeleted, isError: false);
                  _loadDraftSales();
                }
              } catch (e) {
                if (mounted)
                  _showSnack("${l10n.deleteError}: $e", isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.delete),
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;

    await _loadDraftSales();
    final customerId = debtor['customerId'];
    final debtorSales =
        _debtSales.where((sale) => sale['customerId'] == customerId).toList();

    if (debtorSales.isEmpty) {
      _showSnack(l10n.noDebtSalesFound, isError: false);
      return;
    }

    if (!mounted) return;

    showPaymentHistorySheet(
      context,
      customerName: debtor['customerName'] ?? l10n.noCustomer,
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

  // ───────────────────────── Tab colors ─────────────────────────
  // Mirror the HTML mockup palette: blue for Draft (the "resume" state),
  // amber for Debt, green for Paid/Closed, red for debtor customers.
  static const _draftColor = Color(0xFF3B82F6);
  static const _debtColor = Color(0xFFFCD34D);
  static const _paidColor = Color(0xFF10B981);
  static const _debtorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadAll,
      child: Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    DavomSegmentedControl(
                      active: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                      tabs: [
                        DavomTabSpec(
                          tab: DavomTab.davom,
                          label: l10n.ongoing,
                          count: _draftSales.length,
                          color: _draftColor,
                        ),
                        DavomTabSpec(
                          tab: DavomTab.qarz,
                          label: l10n.debt,
                          count: _debtSales.length,
                          color: _debtColor,
                        ),
                        DavomTabSpec(
                          tab: DavomTab.paid,
                          label: l10n.paid,
                          count: _paidSales.length,
                          color: _paidColor,
                        ),
                        DavomTabSpec(
                          tab: DavomTab.qarzdor,
                          label: l10n.debtorCustomers,
                          count: _debtors.length,
                          color: _debtorColor,
                        ),
                      ],
                      summaryLabel: _summaryLabel(l10n),
                      summaryValue: _summaryValue(),
                    ),
                    const SizedBox(height: 12),
                    ..._buildTabBody(l10n),
                  ],
                ),
              ),
      ),
    );
  }

  String _summaryLabel(AppLocalizations l10n) {
    switch (_tab) {
      case DavomTab.davom:
        return l10n.ongoing;
      case DavomTab.qarz:
        return l10n.debtSales;
      case DavomTab.paid:
        return l10n.paidSales;
      case DavomTab.qarzdor:
        return l10n.debtorCustomers;
    }
  }

  String _summaryValue() {
    switch (_tab) {
      case DavomTab.davom:
        return formatSalesSummary(_draftSales);
      case DavomTab.qarz:
        return formatSalesSummary(_debtSales);
      case DavomTab.paid:
        return formatSalesSummary(_paidSales);
      case DavomTab.qarzdor:
        return formatDebtorsSummary(_debtors);
    }
  }

  List<Widget> _buildTabBody(AppLocalizations l10n) {
    switch (_tab) {
      case DavomTab.davom:
        if (_draftSales.isEmpty) return [const EmptyState()];
        return _draftSales
            .map((sale) => ContinuingSaleRow(
                  sale: sale,
                  stripColor: _draftColor,
                  amountColor: _draftColor,
                  hintLabel: 'DAVOM',
                  onTap: () => _continueSale(sale),
                  onDelete: () => _confirmDelete(sale['id']),
                ))
            .toList();

      case DavomTab.qarz:
        if (_debtSales.isEmpty) return [const EmptyState()];
        return _debtSales
            .map((sale) => ContinuingSaleRow(
                  sale: sale,
                  stripColor: _debtColor,
                  amountColor: _debtColor,
                  // Debt sales are locked for editing — tap surfaces the
                  // correct flow (pay via Qarzdor section) instead of
                  // dumping the user into a broken edit screen.
                  onTap: () => _showSnack(
                    l10n.saleInDebtUseDebtorsSection,
                    isError: false,
                  ),
                  onDelete: () => _confirmDelete(sale['id']),
                ))
            .toList();

      case DavomTab.paid:
        if (_paidSales.isEmpty) return [const EmptyState()];
        return _paidSales
            .map((sale) => ContinuingSaleRow(
                  sale: sale,
                  stripColor: _paidColor,
                  amountColor: _paidColor,
                  onTap: () =>
                      _showSnack(l10n.saleAlreadyPaid, isError: false),
                  onDelete: () => _confirmDelete(sale['id']),
                ))
            .toList();

      case DavomTab.qarzdor:
        if (_debtors.isEmpty) return [const EmptyState()];
        return _debtors
            .map((debtor) => DebtorCard(
                  debtor: debtor,
                  onPaymentTap: () => _showDebtorPayment(debtor),
                  onHistoryTap: () => _showPaymentHistory(debtor),
                ))
            .toList();
    }
  }
}
