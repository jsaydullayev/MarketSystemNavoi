import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/customer_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../screens/dashboard_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<dynamic> _customers = [];
  List<dynamic> _filteredCustomers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final fullName = (customer['fullName'] ?? '').toLowerCase();
          final phone = (customer['phone'] ?? '').toLowerCase();
          return fullName.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerService = CustomerService(authProvider: authProvider);

      final customers = await customerService.getAllCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCustomer(dynamic customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mijozni o\'chirish'),
        content: Text('${customer['fullName'] ?? customer['phone']} mijozini rostdan ham o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ha'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final customerService = CustomerService(authProvider: authProvider);

        await customerService.deleteCustomer(customer['id']);
        await _loadCustomers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mijoz muvaffaqiyatli o\'chirildi'),
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

  void _showAddCustomerDialog() {
    final phoneController = TextEditingController();
    final fullNameController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yangi mijoz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'To\'liq ism (ixtiyoriy)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (phoneController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Telefon raqam kiritish shart'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final customerService = CustomerService(authProvider: authProvider);

                        await customerService.createCustomer(
                          phone: phoneController.text.trim(),
                          fullName: fullNameController.text.trim().isEmpty ? null : fullNameController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          await _loadCustomers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mijoz muvaffaqiyatli qo\'shildi'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Xatolik: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerInfo(dynamic customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['fullName'] ?? 'Noma\'lum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telefon: ${customer['phone'] ?? 'Noma\'lum'}'),
            const SizedBox(height: 8),
            Text('Qarz: ${customer['totalDebt'] ?? 0} so\'m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijozlar'),
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
            onPressed: _loadCustomers,
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
              onChanged: (_) => _filterCustomers(),
              decoration: InputDecoration(
                hintText: 'Mijoz qidirish...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCustomers();
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

          // Customers list
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
                              onPressed: _loadCustomers,
                              child: const Text('Qayta urinish'),
                            ),
                          ],
                        ),
                      )
                    : _filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Mijoz topilmadi'
                                      : 'Mijozlar yo\'q',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCustomers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = _filteredCustomers[index];
                                return _buildCustomerCard(customer);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Yangi mijoz'),
      ),
    );
  }

  Widget _buildCustomerCard(dynamic customer) {
    final totalDebt = customer['totalDebt'] ?? 0;
    final hasDebt = totalDebt > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: hasDebt ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            color: hasDebt ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          customer['fullName'] ?? 'Noma\'lum',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${customer['phone'] ?? 'Noma\'lum'}'),
            const SizedBox(height: 4),
            if (hasDebt)
              Text(
                'Qarz: $totalDebt so\'m',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                'Qarzsiz',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showCustomerInfo(customer),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCustomer(customer),
            ),
          ],
        ),
      ),
    );
  }
}
