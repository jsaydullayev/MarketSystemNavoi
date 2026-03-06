import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/features/debts/widgets/debt_summary_header.dart';
import 'package:market_system_client/features/debts/widgets/edit_price_bottomsheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../data/services/sales_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/number_formatter.dart';

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
  List<dynamic> _saleItems = [];

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _saleItems = widget.debt['saleItems'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('Xatolik: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openEditSheet(dynamic saleItem) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final debtStatus = widget.debt['status'];

    if (debtStatus == 'Closed' && userRole != 'Owner' && userRole != 'Admin') {
      _showError(l10n.noPermissionToEditClosed);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPriceBottomSheet(
        saleItem: saleItem,
        debtStatus: debtStatus,
        userRole: userRole,
        onSave: (newPrice, comment) async {
          await _updatePrice(saleItem, newPrice, comment);
        },
      ),
    );
  }

  Future<void> _updatePrice(
      dynamic saleItem, double newPrice, String comment) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final saleService = SalesService(authProvider: authProvider);
      await saleService.updateSaleItemPrice(
        saleItemId: saleItem['id'],
        newPrice: newPrice,
        comment: comment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.priceUpdatedSuccess),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadSaleDetails();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('${l10n.error}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final debtStatus = widget.debt['status'];
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NetworkWrapper(
      onRetry: _loadSaleDetails,
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(title: l10n.debtDetails),
        body: Column(
          children: [
            DebtSummaryHeader(
              customerName: widget.customerName,
              debt: widget.debt,
              debtStatus: debtStatus,
              l10n: l10n,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _saleItems.isEmpty
                      ? const _EmptySaleItemsView()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _saleItems.length,
                          itemBuilder: (context, index) {
                            final item = _saleItems[index];
                            return _SaleItemCard(
                              item: item,
                              userRole: userRole,
                              debtStatus: debtStatus,
                              onEdit: () => _openEditSheet(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleItemCard extends StatelessWidget {
  final dynamic item;
  final String? userRole;
  final String debtStatus;
  final VoidCallback onEdit;

  const _SaleItemCard({
    required this.item,
    required this.userRole,
    required this.debtStatus,
    required this.onEdit,
  });

  bool get _canEdit {
    if (debtStatus == 'Open') return userRole != null;
    return userRole == 'Owner' || userRole == 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productName = item['productName'] ?? l10n.unknown;
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num).toDouble();
    final totalPrice = salePrice * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 3),
                Text(
                  '${quantity.toStringAsFixed(0)} ${l10n.piece} × ${NumberFormatter.format(salePrice)} ${l10n.currencySom}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormatter.format(totalPrice)} ${l10n.currencySom}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                  letterSpacing: -0.5,
                ),
              ),
              if (_canEdit) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 12, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 4),
                        Text(
                          l10n.edit,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySaleItemsView extends StatelessWidget {
  const _EmptySaleItemsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_rounded,
              size: 52, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(l10n.noProducts,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
