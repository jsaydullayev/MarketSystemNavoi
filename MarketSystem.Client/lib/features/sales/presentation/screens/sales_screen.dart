import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sale_entity.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/states/sales_state.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedStatus = 'all';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    context.read<SalesBloc>().add(const GetSalesEvent());
  }

  List<SaleEntity> _filterSales(List<SaleEntity> sales) {
    if (_selectedStatus == 'all') return sales;
    return sales
        .where((s) => s.getStatusText().toLowerCase() == _selectedStatus)
        .toList();
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'closed':
        return Colors.blue;
      case 'debt':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return theme.primaryColor;
    }
  }

  String _getStatusName(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'draft':
        return l10n.draft;
      case 'paid':
        return l10n.paid;
      case 'closed':
        return l10n.close;
      case 'debt':
        return l10n.debt;
      default:
        return status;
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final bytes = await salesService.downloadSalesExcel();

      if (bytes != null && bytes.isNotEmpty) {
        final path = await core_file_helper.FileHelper.saveAndOpenExcel(
            bytes, 'Sotuvlar.xlsx');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(path != null ? 'Excel OK: $path' : 'Error'),
                backgroundColor: path != null ? Colors.green : Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.sales,
          onRefresh: _loadSales,
          extraActions: [
            _isExporting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    onPressed: _exportExcel,
                  ),
          ],
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                if (state is SalesLoading)
                  return const Center(child: CircularProgressIndicator());

                if (state is SalesLoaded) {
                  final filteredSales = _filterSales(state.sales);
                  return Column(
                    children: [
                      _buildSummaryHeader(state.sales, theme, l10n, isDark),
                      _buildStatusChips(state.sales, theme, isDark, l10n),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => _loadSales(),
                          child: filteredSales.isEmpty
                              ? _buildEmptyState(theme, l10n)
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: filteredSales.length,
                                  itemBuilder: (context, index) =>
                                      _buildSaleItem(filteredSales[index],
                                          theme, isDark, l10n),
                                ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                        value: context.read<SalesBloc>(),
                        child: const NewSaleScreen())));
            if (result == true && mounted) _loadSales();
          },
          icon:
              const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
          label: Text(l10n.newSale,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<SaleEntity> sales, ThemeData theme,
      AppLocalizations l10n, bool isDark) {
    double total = sales.fold(0, (sum, item) => sum + item.totalAmount);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : theme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3), blurRadius: 12)
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.totalAmount,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(NumberFormatter.format(total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const Icon(Icons.payments_outlined,
                  color: Colors.white24, size: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(List<SaleEntity> sales, ThemeData theme, bool isDark,
      AppLocalizations l10n) {
    final List<Map<String, dynamic>> statuses = [
      {
        'id': 'all',
        'label': l10n.all,
        'icon': Icons.grid_view_rounded,
        'color': theme.primaryColor
      },
      {
        'id': 'draft',
        'label': l10n.draft,
        'icon': Icons.pending_actions_rounded,
        'color': Colors.orange
      },
      {
        'id': 'paid',
        'label': l10n.paid,
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.green
      },
      {
        'id': 'closed',
        'label': l10n.closed,
        'icon': Icons.archive_outlined,
        'color': Colors.blue
      },
      {
        'id': 'debt',
        'label': l10n.debt,
        'icon': Icons.error_outline_rounded,
        'color': Colors.red
      },
    ];

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final s = statuses[index];
          final bool isSelected = _selectedStatus == s['id'];
          final Color color = s['color'] as Color;
          final int count = s['id'] == 'all'
              ? sales.length
              : sales
                  .where(
                      (item) => item.getStatusText().toLowerCase() == s['id'])
                  .length;

          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = s['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white10 : Colors.grey[200]!),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: isSelected ? Colors.white : color,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "$count",
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : theme.disabledColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaleItem(
      SaleEntity sale, ThemeData theme, bool isDark, AppLocalizations l10n) {
    final statusColor = _getStatusColor(sale.getStatusText(), theme);
    final dateStr = DateFormat('dd MMM, HH:mm').format(sale.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SaleDetailScreen(saleId: sale.id))),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15)),
          child: Icon(Icons.receipt_long_rounded, color: statusColor),
        ),
        title: Text(sale.customerName ?? (l10n.noCustomer),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dateStr,
            style: TextStyle(color: theme.disabledColor, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(NumberFormatter.format(sale.totalAmount),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  _getStatusName(sale.getStatusText(), l10n).toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 70, color: theme.disabledColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(l10n.noData, style: TextStyle(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
