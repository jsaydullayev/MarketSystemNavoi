import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/states/sales_state.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  void _loadSaleDetails() {
    context.read<SalesBloc>().add(GetSaleDetailEvent(widget.saleId));
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'debt':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      case 'closed':
        return theme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: Colors.red));
        } else if (state is SaleItemReturned) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.returnSuccess),
              backgroundColor: Colors.green));
          _loadSaleDetails();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: AppBar(
          backgroundColor: AppColors.getCard(isDark),
          elevation: 0,
          title: Text(l10n.sales,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              context.read<SalesBloc>().add(const GetSalesEvent());
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadSaleDetails),
          ],
        ),
        body: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            if (state is SaleDetailLoading)
              return const Center(child: CircularProgressIndicator());
            if (state is SaleDetailLoaded)
              return _buildBody(state.sale, theme, isDark, l10n);
            return Center(child: Text(l10n.errorOccurred));
          },
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> sale, ThemeData theme, bool isDark,
      AppLocalizations l10n) {
    final status = sale['status']?.toString() ?? '';
    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = totalAmount - paidAmount;
    final items = sale['items'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(sale, theme, isDark, l10n, status),
          _buildFinancialCard(
              totalAmount, paidAmount, remainingAmount, theme, isDark, l10n),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 20),
                8.width,
                Text(l10n.all,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildProductItem(items[index], status, theme, isDark),
          ),
          32.height,
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> sale, ThemeData theme, bool isDark,
      AppLocalizations l10n, String status) {
    final color = _getStatusColor(status, theme);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale['customerName'] ?? 'Mijozsiz',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    4.height,
                    Text(
                        DateFormat('dd.MM.yyyy HH:mm')
                            .format(DateTime.parse(sale['createdAt'])),
                        style: TextStyle(color: theme.disabledColor)),
                  ],
                ),
              ),
              _buildStatusBadge(status, color),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(Icons.person_outline, l10n.seller,
              sale['sellerName'] ?? "Noma'lum", theme),
          if (sale['customerPhone'] != null) ...[
            16.height,
            _buildInfoRow(
                Icons.phone_outlined, l10n.phone, sale['customerPhone'], theme),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialCard(double total, double paid, double debt,
      ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          _buildFinRow(l10n.totalSum, total, Colors.white, 20),
          16.height,
          Row(
            children: [
              Expanded(
                  child: _buildFinMiniRow(
                      l10n.paid, paid, Colors.white.withOpacity(0.8))),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                  child: _buildFinMiniRow(
                      l10n.debt,
                      debt,
                      debt > 0
                          ? Colors.orangeAccent
                          : Colors.white.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      Map<String, dynamic> item, String status, ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final canReturn =
        status.toLowerCase() == 'paid' || status.toLowerCase() == 'debt';
    final qty = (item['quantity'] as num).toDouble();
    final price = (item['salePrice'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.shopping_bag_outlined, color: theme.primaryColor),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? l10n.unknown,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text("$qty x ${NumberFormatter.format(price)}",
                    style: TextStyle(color: theme.disabledColor, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(NumberFormatter.format(item['totalPrice']),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Colors.green)),
              if (canReturn)
                GestureDetector(
                  onTap: () => _showReturnBottomSheet(item),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.returnAction,
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1)),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.disabledColor),
        12.width,
        Text(label, style: TextStyle(color: theme.disabledColor)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFinRow(
      String label, double amount, Color color, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
        Text(NumberFormatter.format(amount),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: fontSize)),
      ],
    );
  }

  Widget _buildFinMiniRow(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
        4.height,
        Text(NumberFormatter.format(amount),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _showReturnBottomSheet(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productName = item['productName'] ?? l10n.unknownProduct;
    final saleItemId = item['id']?.toString() ?? '';
    final maxQuantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;

    final quantityController = TextEditingController(text: '1');
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context)!;
          double currentQty = double.tryParse(quantityController.text) ?? 0.0;
          double returnSum = currentQty * salePrice;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: theme.disabledColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                20.height,
                Row(
                  children: [
                    const Icon(Icons.keyboard_return_rounded,
                        color: Colors.orange, size: 28),
                    12.width,
                    Text(l10n.processReturn,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 32),
                Text(productName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                4.height,
                Text("${l10n.maxReturn}: $maxQuantity ${l10n.piece}",
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.w600)),
                24.height,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFieldLabel(
                          l10n.amount,
                          theme,
                          TextField(
                            controller: quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (v) => setSheetState(() {}),
                            decoration: _inputStyle(theme, isDark, "1",
                                suffix: l10n.piece),
                          )),
                    ),
                    12.width,
                    Expanded(
                      flex: 3,
                      child: _buildFieldLabel(
                          l10n.reasonOptional,
                          theme,
                          TextField(
                            controller: commentController,
                            decoration: _inputStyle(theme, isDark, l10n.defect),
                          )),
                    ),
                  ],
                ),
                24.height,
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${l10n.returnAmount}:",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(NumberFormatter.format(returnSum),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                24.height,
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      final qty = double.tryParse(quantityController.text);
                      if (qty == null || qty <= 0 || qty > maxQuantity) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l10n.invalidQuantity),
                            backgroundColor: Colors.red));
                        return;
                      }
                      Navigator.pop(context);
                      context.read<SalesBloc>().add(ReturnSaleItemEvent(
                            saleId: widget.saleId,
                            saleItemId: saleItemId,
                            quantity: qty,
                            comment: commentController.text.isEmpty
                                ? null
                                : commentController.text,
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(l10n.finishReturn,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeData theme, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: theme.disabledColor,
                fontWeight: FontWeight.bold)),
        8.height,
        child,
      ],
    );
  }

  InputDecoration _inputStyle(ThemeData theme, bool isDark, String hint,
      {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
