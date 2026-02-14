import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/services/reports_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/number_formatter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late ReportsService _reportsService;

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _periodReport;
  Map<String, dynamic>? _comprehensiveReport;

  bool _isLoading = false;
  String _selectedTab = 'daily'; // daily, monthly, inventory

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _reportsService = ReportsService(authProvider: authProvider);
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily report
      final daily = await _reportsService.getDailyReport(_selectedDate);

      // Load period report (last 30 days)
      final period = await _reportsService.getPeriodReport(_startDate, _endDate);

      // Load comprehensive report
      final comprehensive = await _reportsService.getComprehensiveReport(_selectedDate);

      setState(() {
        _dailyReport = daily;
        _periodReport = period;
        _comprehensiveReport = comprehensive;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobotlar'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Kunlik', 'daily', Icons.today),
                const SizedBox(width: 8),
                _buildTab('Oylik', 'monthly', Icons.calendar_month),
                const SizedBox(width: 8),
                _buildTab('Sklad', 'inventory', Icons.inventory),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildSelectedReport(),
              ),
            ),
    );
  }

  Widget _buildTab(String label, String value, IconData icon) {
    final isSelected = _selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedReport() {
    switch (_selectedTab) {
      case 'daily':
        return _buildDailyReport();
      case 'monthly':
        return _buildMonthlyReport();
      case 'inventory':
        return _buildInventoryReport();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDailyReport() {
    if (_dailyReport == null) {
      return const Center(child: Text('Hisobotlar yo\'q'));
    }

    final totalSales = (_dailyReport!['totalSales'] as num).toDouble();
    final totalTransactions = _dailyReport!['totalTransactions'] as int;
    final profit = (_dailyReport!['profit'] as num).toDouble();

    // Payment breakdown
    final paymentBreakdown = _dailyReport!['paymentBreakdown'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date picker
        _buildDatePicker(),

        const SizedBox(height: 20),

        // Summary cards row
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Kunlik savdo',
                NumberFormatter.formatDecimal(totalSales),
                Icons.trending_up,
                Colors.green,
                subtitle: '$totalTransactions ta savdo',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Foyda',
                NumberFormatter.formatDecimal(profit),
                Icons.account_balance_wallet,
                Colors.blue,
                subtitle: 'Sof foyda',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Payment breakdown section
        if (paymentBreakdown.isNotEmpty) ...[
          const Text(
            'To\'lov turlari bo\'yicha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...paymentBreakdown.map((payment) {
            final paymentType = payment['paymentType'] as String;
            final amount = (payment['amount'] as num).toDouble();
            final count = payment['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPaymentCard(
                paymentType,
                amount,
                count,
                totalSales,
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Export button
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportToExcel('daily'),
            icon: const Icon(Icons.file_download),
            label: const Text('Excelga yuklab olish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReport() {
    if (_periodReport == null) {
      return const Center(child: Text('Hisobotlar yo\'q'));
    }

    final totalSales = (_periodReport!['totalSales'] as num).toDouble();
    final totalTransactions = _periodReport!['totalTransactions'] as int;
    final profit = (_periodReport!['profit'] as num).toDouble();
    final avgSale = (_periodReport!['averageSale'] as num).toDouble();

    // Payment breakdown
    final paymentBreakdown = _periodReport!['paymentBreakdown'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range picker
        _buildDateRangePicker(),

        const SizedBox(height: 20),

        // Summary cards row 1
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Jami savdo',
                NumberFormatter.formatDecimal(totalSales),
                Icons.attach_money,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Savdolar soni',
                '$totalTransactions ta',
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Average sale card
        _buildSummaryCard(
          'O\'rtacha savdo',
          NumberFormatter.formatDecimal(avgSale),
          Icons.calculate,
          Colors.purple,
          subtitle: 'Har bir savdoning o\'rtacha summasi',
        ),

        const SizedBox(height: 12),

        // Profit card
        _buildSummaryCard(
          'Foyda',
          NumberFormatter.formatDecimal(profit),
          Icons.account_balance_wallet,
          Colors.green,
          subtitle: 'Sof foyda',
        ),

        const SizedBox(height: 16),

        // Payment breakdown section
        if (paymentBreakdown.isNotEmpty) ...[
          const Text(
            'To\'lov turlari bo\'yicha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...paymentBreakdown.map((payment) {
            final paymentType = payment['paymentType'] as String;
            final amount = (payment['amount'] as num).toDouble();
            final count = payment['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPaymentCard(
                paymentType,
                amount,
                count,
                totalSales,
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Export button
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportToExcel('monthly'),
            icon: const Icon(Icons.file_download),
            label: const Text('Excelga yuklab olish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryReport() {
    if (_comprehensiveReport == null) {
      return const Center(child: Text('Hisobotlar yo\'q'));
    }

    final inventory = _comprehensiveReport!['inventoryReport'] as List<dynamic>? ?? [];
    final totalInventoryCost = (_comprehensiveReport!['totalInventoryCost'] as num).toDouble();
    final totalInventorySaleValue = (_comprehensiveReport!['totalInventorySaleValue'] as num).toDouble();
    final potentialProfit = totalInventorySaleValue - totalInventoryCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date picker
        _buildDatePicker(),

        const SizedBox(height: 20),

        // Summary cards row 1
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Mahsulotlar soni',
                '${inventory.length} ta',
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Kelgan narxi',
                NumberFormatter.formatDecimal(totalInventoryCost),
                Icons.shopping_bag,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Summary cards row 2
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Sotish narxi',
                NumberFormatter.formatDecimal(totalInventorySaleValue),
                Icons.sell,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Potensial foyda',
                NumberFormatter.formatDecimal(potentialProfit),
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Products list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mahsulotlar ro\'yxati',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Jami: ${inventory.length} ta',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Products list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: inventory.length > 50 ? 50 : inventory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = inventory[index] as Map<String, dynamic>;
            return _buildInventoryItemCard(item);
          },
        ),

        if (inventory.length > 50) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Va ${inventory.length - 50} ta mahsulot ko\'proq...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Export button
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportToExcel('inventory'),
            icon: const Icon(Icons.file_download),
            label: const Text('Excelga yuklab olish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(Map<String, dynamic> item) {
    final name = item['productName'] ?? 'Noma\'lum';
    final quantity = item['quantity'] as int;
    final costPrice = (item['costPrice'] as num).toDouble();
    final salePrice = (item['salePrice'] as num).toDouble();
    final profit = (salePrice - costPrice) * quantity;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$quantity ta • ${NumberFormatter.formatDecimal(costPrice)} so\'m',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormatter.formatDecimal(salePrice * quantity),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '+${NumberFormatter.formatDecimal(profit)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('dd.MM.yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
                _loadReports();
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
                _loadReports();
              },
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _loadReports();
                }
              },
              child: const Text('Tanlash'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        DateFormat('dd.MM.yyyy').format(_startDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Text('-'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Gacha', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        DateFormat('dd.MM.yyyy').format(_endDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _loadReports();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 4,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(String paymentType, double amount, int count, double totalSales) {
    // Map payment type to Uzbek and icon/color
    final Map<String, Map<String, dynamic>> paymentConfig = {
      'Cash': {'name': 'Naqd', 'icon': Icons.money, 'color': Colors.green},
      'Terminal': {'name': 'Terminal', 'icon': Icons.credit_card, 'color': Colors.orange},
      'Transfer': {'name': 'Hisob raqam', 'icon': Icons.account_balance, 'color': Colors.purple},
      'Click': {'name': 'Click', 'icon': Icons.touch_app, 'color': Colors.blue},
    };

    final config = paymentConfig[paymentType] ?? {'name': paymentType, 'icon': Icons.payment, 'color': Colors.grey};
    final icon = config['icon'] as IconData;
    final color = config['color'] as Color;
    final name = config['name'] as String;

    final percentage = totalSales > 0 ? (amount / totalSales * 100).toStringAsFixed(1) : '0.0';

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$count ta tranzaksiya • $percentage%'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${NumberFormatter.formatDecimal(amount)} so\'m',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToExcel(String reportType) {
    String url = '';
    String filename = '';

    if (reportType == 'daily') {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      url = 'http://10.0.2.2:5137/api/Reports/ExportToExcel?start=$dateStr&end=$dateStr';
      filename = 'daily_report_${DateFormat('yyyyMMdd').format(_selectedDate)}.xlsx';
    } else if (reportType == 'monthly') {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      url = 'http://10.0.2.2:5137/api/Reports/ExportToExcel?start=$startStr&end=$endStr';
      filename = 'period_report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.xlsx';
    } else if (reportType == 'inventory') {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      url = 'http://10.0.2.2:5137/api/Reports/ExportComprehensiveToExcel?date=$dateStr';
      filename = 'inventory_report_${DateFormat('yyyyMMdd').format(_selectedDate)}.xlsx';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel fayli yuklab olish:\n$filename\n\nURL: $url'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
