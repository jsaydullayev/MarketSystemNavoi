import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/sales_service.dart';
import '../../../data/models/profit_model.dart';

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
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailySales();
    }
  }

  Future<void> _refreshSales() async {
    await _loadDailySales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kunlik Savdolar',
          style: AppTheme.headingMedium.copyWith(
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppTheme.primary),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy', 'uz_UZ').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_isLoading && _dailySales == null)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _dailySales == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailySales,
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }

    if (_dailySales == null || _dailySales!.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Bu sana bo\'yicha savdolar yo\'q',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSales,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card - minimal
            _buildSummaryCard(),

            const SizedBox(height: 12),

            // Sales grid - 3 columns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savdolar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${_dailySales!.sales.length} ta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: _dailySales!.sales.length,
              itemBuilder: (context, index) {
                final sale = _dailySales!.sales[index];
                return _buildMinimalSaleCard(sale);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?['role'] == 'Owner';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwner ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // First row: Sales count and profit (Owner only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                _dailySales!.sales.length.toString(),
                'savdo',
                isOwner ? Colors.white : AppTheme.primary,
              ),
              if (isOwner)
                _buildSummaryItem(
                  _formatAmount(_dailySales!.summaryProfit ?? 0),
                  'foyda',
                  Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row: Paid sales
          _buildSummaryItem(
            _formatAmount(_dailySales!.totalPaidSales),
            'to\'langan',
            isOwner ? Colors.white : Colors.green,
          ),
          const SizedBox(height: 6),
          // Third row: Debt sales
          _buildSummaryItem(
            _formatAmount(_dailySales!.totalDebtSales),
            'qarzga sotilgan',
            isOwner ? Colors.white : Colors.orange.shade700,
          ),
          const SizedBox(height: 6),
          // Fourth row: Total sales
          _buildSummaryItem(
            _formatAmount(_dailySales!.totalSales),
            'jami savdo',
            isOwner ? Colors.white : AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalSaleCard(DailySalesListItemModel sale) {
    final statusColor = _getStatusColor(sale.status);
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?['role'] == 'Owner';

    return GestureDetector(
      onTap: () => _showSaleDetails(sale),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status dot and time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(sale.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Seller name - ultra short
            Text(
              sale.sellerName.split(' ').first,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Amount - main focus
            Text(
              _formatAmount(sale.totalAmount),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: statusColor,
                letterSpacing: -0.5,
              ),
            ),

            // Payment icon only
            Icon(
              _getPaymentIcon(sale.paymentType),
              size: 13,
              color: Colors.grey.shade400,
            ),

            // Profit badge for owner - compact
            if (isOwner && sale.profit != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '+${_formatAmount(sale.profit!)}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Future<void> _showSaleDetails(DailySalesListItemModel sale) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final salesService = SalesService(authProvider: authProvider);
    final isOwner = authProvider.user?['role'] == 'Owner';

    try {
      final saleDetails = await salesService.getSaleById(sale.id);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _SaleDetailSheet(
          sale: sale,
          saleDetails: saleDetails,
          isOwner: isOwner,
          onRefresh: () {
            Navigator.pop(context);
            _loadDailySales();
          },
        ),
      );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'closed':
        return Colors.blue;
      case 'debt':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'click':
        return Icons.touch_app;
      default:
        return Icons.payment;
    }
  }
}

class _SaleDetailSheet extends StatelessWidget {
  final DailySalesListItemModel sale;
  final Map<String, dynamic> saleDetails;
  final bool isOwner;
  final VoidCallback onRefresh;

  const _SaleDetailSheet({
    required this.sale,
    required this.saleDetails,
    required this.isOwner,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final items = saleDetails['saleItems'] as List<dynamic>? ?? [];
    final payments = saleDetails['payments'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sale info
                  _buildSaleInfo(),

                  const SizedBox(height: 16),

                  // Items
                  Text(
                    'Mahsulotlar (${items.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => _buildItemCard(item)),

                  const SizedBox(height: 16),

                  // Payments
                  if (payments.isNotEmpty) ...[
                    Text(
                      'To\'lovlar (${payments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...payments.map((payment) => _buildPaymentCard(payment)),
                    const SizedBox(height: 16),
                  ],

                  // Totals
                  _buildTotalsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savdo #${sale.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sale.sellerName} • ${DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(sale.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(sale.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(sale.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (sale.customerName != null) ...[
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Mijoz: ${sale.customerName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(
                _getPaymentIcon(sale.paymentType),
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'To\'lov turi: ${_getPaymentTypeText(sale.paymentType)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final productName = item['productName'] ?? 'Noma\'lum';
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final total = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final comment = item['comment'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (comment != null && comment.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${quantity == quantity.toInt() ? quantity.toInt() : quantity} ta',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${total.toStringAsFixed(0)} so\'m',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final type = payment['paymentType'] ?? 'cash';
    final time = payment['createdAt'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(payment['createdAt']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _getPaymentIcon(type),
            size: 20,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPaymentTypeText(type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${amount.toStringAsFixed(0)} so\'m',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    final totalAmount = sale.totalAmount;
    final profit = isOwner ? sale.profit : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jami summa:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(0)} so\'m',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (profit != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foyda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '+${profit.toStringAsFixed(0)} so\'m',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'closed':
        return Colors.blue;
      case 'debt':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'To\'langan';
      case 'closed':
        return 'Yopilgan';
      case 'debt':
        return 'Qarzdorlik';
      case 'draft':
        return 'Qoralama';
      case 'cancelled':
        return 'Bekor qilingan';
      default:
        return status;
    }
  }

  IconData _getPaymentIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
      case 'terminal':
        return Icons.credit_card;
      case 'click':
        return Icons.touch_app;
      case 'transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentTypeText(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'cash':
        return 'Naqd';
      case 'card':
        return 'Karta';
      case 'terminal':
        return 'Terminal';
      case 'click':
        return 'Click';
      case 'transfer':
        return 'O\'tkazma';
      default:
        return paymentType;
    }
  }
}
