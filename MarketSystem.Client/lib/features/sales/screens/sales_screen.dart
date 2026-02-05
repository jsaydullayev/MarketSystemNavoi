import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/sales_service.dart';
import '../../../data/services/product_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../screens/dashboard_screen.dart';
import 'new_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<dynamic> _sales = [];
  List<dynamic> _filteredSales = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String _selectedStatus = 'All'; // All, Draft, Completed, Cancelled

  @override
  void initState() {
    super.initState();
    _loadSales();
    _searchController.addListener(_filterSales);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSales() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSales = _sales.where((sale) {
        // Status filter
        if (_selectedStatus != 'All') {
          final status = sale['status']?.toString().toLowerCase() ?? '';
          if (status != _selectedStatus.toLowerCase()) return false;
        }

        // Search filter
        if (query.isEmpty) return true;

        final customerName = (sale['customerName'] ?? '').toLowerCase();
        final customerPhone = (sale['customerPhone'] ?? '').toLowerCase();
        final sellerName = (sale['sellerName'] ?? '').toLowerCase();

        return customerName.contains(query) ||
               customerPhone.contains(query) ||
               sellerName.contains(query);
      }).toList();
    });
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);

      final sales = await salesService.getAllSales();
      setState(() {
        _sales = sales;
        _filteredSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSale(dynamic sale) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];

    if (userRole != 'Admin' && userRole != 'Owner') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faqat Admin va Owner sotuvni bekor qila oladi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sotuvni bekor qilish'),
        content: Text('Rostdan ham bu sotuvni bekor qilmoqchimisiz?\n\nMijoz: ${sale['customerName'] ?? 'Noma\'lum'}\nSumma: ${sale['totalAmount'] ?? 0} so\'m'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final salesService = SalesService(authProvider: authProvider);
        final userId = authProvider.user?['userId'];

        await salesService.cancelSale(
          saleId: sale['id'],
          adminId: userId,
        );

        await _loadSales();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sotuv muvaffaqiyatli bekor qilindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'];
    final canCancel = userRole == 'Admin' || userRole == 'Owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sotuvlar'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterSales(),
              decoration: InputDecoration(
                hintText: 'Mijoz qidirish...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSales();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Status filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('All', 'Barchasi'),
                  const SizedBox(width: 8),
                  _buildStatusChip('Draft', 'Qoralama'),
                  const SizedBox(width: 8),
                  _buildStatusChip('Completed', 'Tugatilgan'),
                  const SizedBox(width: 8),
                  _buildStatusChip('Cancelled', 'Bekor qilingan'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sales list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSales,
                              child: const Text('Qayta urinish'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSales.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Sotuvlar yo\'q',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSales,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSales.length,
                              itemBuilder: (context, index) {
                                final sale = _filteredSales[index];
                                return _buildSaleCard(sale, canCancel);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewSaleScreen(),
            ),
          );
          if (result == true) {
            _loadSales();
          }
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Yangi sotuv'),
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
          _filterSales();
        });
      },
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildSaleCard(dynamic sale, bool canCancel) {
    final status = sale['status']?.toString().toLowerCase() ?? '';
    final statusColor = _getStatusColor(status);
    final totalAmount = (sale['totalAmount'] ?? 0).toDouble();
    final paidAmount = (sale['paidAmount'] ?? 0).toDouble();
    final remainingAmount = (sale['remainingAmount'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(status),
            color: statusColor,
          ),
        ),
        title: Text(
          'Mijoz: ${sale['customerName'] ?? 'Noma\'lum'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sale['customerPhone'] != null)
              Text('Tel: ${sale['customerPhone']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    _getStatusText(status),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: statusColor.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(sale['createdAt']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jami summa:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${totalAmount.toStringAsFixed(0)} so\'m',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('To\'langan:'),
                    Text(
                      '${paidAmount.toStringAsFixed(0)} so\'m',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
                if (remainingAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Qarzdorlik:',
                          style: TextStyle(color: Colors.red)),
                      Text(
                        '${remainingAmount.toStringAsFixed(0)} so\'m',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Sotuvchi: ${sale['sellerName'] ?? 'Noma\'lum'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (canCancel && status != 'cancelled' && status != 'completed') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelSale(sale),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Sotuvni bekor qilish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_note;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Qoralama';
      case 'completed':
        return 'Tugatilgan';
      case 'cancelled':
        return 'Bekor qilingan';
      default:
        return status;
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
