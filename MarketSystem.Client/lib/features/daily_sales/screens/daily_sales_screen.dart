import 'package:flutter/material.dart';
import 'package:market_system_client/features/daily_sales/widgets/daily_summary_card.dart';
import 'package:market_system_client/features/daily_sales/widgets/sale_detail_sheet.dart';
import 'package:market_system_client/features/daily_sales/widgets/sale_grid_item.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/sales_service.dart';
import '../../../data/models/profit_model.dart';
import '../../../l10n/app_localizations.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  DateTime _selectedDate = DateTime.now();
  DailySalesListModel? _dailySales;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDailySales();
  }

  Future<void> _loadDailySales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportService(authProvider: authProvider);
      final sales = await reportService.getDailySalesList(_selectedDate);

      setState(() {
        _dailySales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDailySales();
    }
  }

  Future<void> _showSaleDetails(DailySalesListItemModel sale) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?['role'] == 'Owner';
    final salesService = SalesService(authProvider: authProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final saleDetails = await salesService.getSaleById(sale.id);
      if (!mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SaleDetailSheet(
          sale: sale,
          saleDetails: saleDetails,
          isOwner: isOwner,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          l10n.dailySales,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_rounded, color: theme.primaryColor),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: 800), // Web uchun adaptive
          child: Column(
            children: [
              _buildDateBadge(theme, isDark),
              Expanded(child: _buildBody(l10n, theme, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd MMMM, yyyy').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme, bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadDailySales, child: Text(l10n.loading)),
          ],
        ),
      );
    }

    if (_dailySales == null || _dailySales!.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: theme.disabledColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(l10n.noData, style: TextStyle(color: theme.disabledColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDailySales,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DailySummaryCard(data: _dailySales!),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.sales,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_dailySales!.sales.length} ta',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _dailySales!.sales.length,
            itemBuilder: (context, index) {
              final sale = _dailySales!.sales[index];
              return SaleGridItem(
                sale: sale,
                onTap: () => _showSaleDetails(sale),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
