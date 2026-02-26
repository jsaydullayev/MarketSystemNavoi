import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../screens/dashboard_screen.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../presentation/bloc/customers_bloc.dart';
import '../presentation/bloc/events/customers_event.dart';
import '../presentation/bloc/states/customers_state.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  late final CustomerService _customerService;

  @override
  void initState() {
    super.initState();
    // Initialize customer service
    final authProvider = context.read<AuthProvider>();
    _customerService = CustomerService(authProvider: authProvider);

    // Load customers on init
    context.read<CustomersBloc>().add(const GetCustomersEvent());
    _searchController.addListener(_filterCustomers);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Screen focus qaytganda refresh qilish
    if (mounted) {
      print(
          '🔄 CustomersScreen: didChangeDependencies called, refreshing customers...');
      Future.delayed(Duration.zero, () {
        context.read<CustomersBloc>().add(const GetCustomersEvent());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    setState(() {}); // Trigger rebuild for search filter
  }

  List<Map<String, dynamic>> _getFilteredCustomers(
      List<Map<String, dynamic>> customers) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return customers;
    } else {
      return customers.where((customer) {
        final fullName = (customer['fullName'] ?? '').toLowerCase();
        final phone = (customer['phone'] ?? '').toLowerCase();
        return fullName.contains(query) || phone.contains(query);
      }).toList();
    }
  }

  void _deleteCustomer(dynamic customer) async {
    // Show loading dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // Get customer delete info first
      final deleteInfo =
          await _customerService.getCustomerDeleteInfo(customer['id']);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show confirmation dialog with warning
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mijozni o\'chirish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${customer['fullName'] ?? customer['phone']} mijozini o\'chirmoqchimisiz?'),
              if (deleteInfo['warningMessage'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          deleteInfo['warningMessage'],
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Yo\'q'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ha, o\'chirish'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          context
              .read<CustomersBloc>()
              .add(DeleteCustomerEvent(customer['id']));
        }
      });
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error and proceed with simple delete
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mijozni o\'chirish'),
          content: Text(
              '${customer['fullName'] ?? customer['phone']} mijozini rostdan ham o\'chirmoqchimisiz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Yo\'q'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ha'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          context
              .read<CustomersBloc>()
              .add(DeleteCustomerEvent(customer['id']));
        }
      });
    }
  }

  void _showAddCustomerDialog() {
    final phoneController = TextEditingController();
    final fullNameController = TextEditingController();
    final commentController = TextEditingController();
    final debtAmountController = TextEditingController();

    // Qarz statusini tanlash (default: qarzsiz)
    bool hasDebt = false;

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
              const SizedBox(height: 16),

              // Qarz statusini tanlash tugmalari
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          hasDebt = false;
                          debtAmountController.clear();
                        });
                      },
                      icon: Icon(hasDebt
                          ? Icons.radio_button_unchecked
                          : Icons.radio_button_checked),
                      label: const Text('Qarzsiz'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasDebt ? Colors.grey : Colors.green,
                        side: BorderSide(
                            color: hasDebt ? Colors.grey : Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          hasDebt = true;
                        });
                      },
                      icon: Icon(hasDebt
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                      label: const Text('Qarzdor'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasDebt ? Colors.orange : Colors.grey,
                        side: BorderSide(
                            color: hasDebt ? Colors.orange : Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),

              // Agar qarzdor bo'lsa, qarz miqdorini kiritish field
              if (hasDebt) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: debtAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Qarz miqdori (so\'m)',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                    hintText: 'Misol: 100000',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bu mijoz uchun qarz yozuvi yaratiladi',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Izoh (ixtiyoriy)',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                if (phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Telefon raqam kiritish shart'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Agar qarzdor bo'lsa, miqdorni tekshiramiz
                if (hasDebt && debtAmountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Qarz miqdorini kiritish shart'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final initialDebt = hasDebt
                    ? double.tryParse(debtAmountController.text.trim())
                    : null;

                // Agar qarzdor bo'lsa, miqdor musbat bo'lishi kerak
                if (hasDebt && (initialDebt == null || initialDebt! <= 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Qarz miqdori musbat son bo\'lishi kerak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                context.read<CustomersBloc>().add(CreateCustomerEvent(
                      phone: phoneController.text.trim(),
                      fullName: fullNameController.text.trim().isEmpty
                          ? null
                          : fullNameController.text.trim(),
                      comment: commentController.text.trim().isEmpty
                          ? null
                          : commentController.text.trim(),
                      initialDebt: initialDebt,
                    ));

                Navigator.pop(context);
              },
              child: const Text('Qo\'shish'),
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
            if (customer['comment'] != null &&
                customer['comment'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Izoh:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(customer['comment'] ?? ''),
            ],
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
    return BlocListener<CustomersBloc, CustomersState>(
      listener: (context, state) {
        if (state is CustomerDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mijoz muvaffaqiyatli o\'chirildi'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload customers after deletion
          context.read<CustomersBloc>().add(const GetCustomersEvent());
        } else if (state is CustomerCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mijoz muvaffaqiyatli qo\'shildi'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload customers after creation
          context.read<CustomersBloc>().add(const GetCustomersEvent());
        } else if (state is CustomersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mijozlar'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<CustomersBloc>().add(const GetCustomersEvent()),
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
              child: BlocBuilder<CustomersBloc, CustomersState>(
                builder: (context, state) {
                  if (state is CustomersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is CustomersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<CustomersBloc>()
                                .add(const GetCustomersEvent()),
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is CustomersLoaded) {
                    final customers =
                        state.customers.map((e) => e.toJson()).toList();
                    print(
                        '🏠 CustomersScreen: BlocBuilder rebuilt with ${customers.length} customers');
                    for (var customer in customers) {
                      print(
                          '  - ${customer['fullName']} (${customer['phone']}): ${customer['totalDebt']} so\'m qarz');
                    }
                    final filteredCustomers = _getFilteredCustomers(customers);

                    if (filteredCustomers.isEmpty) {
                      return Center(
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
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<CustomersBloc>()
                            .add(const GetCustomersEvent());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
                    );
                  }

                  // Initial state
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddCustomerDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('Yangi mijoz'),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(dynamic customer) {
    final totalDebt = customer['totalDebt'] ?? 0;
    final hasDebt = totalDebt > 0;
    final comment = customer['comment']?.toString() ?? '';
    final hasComment = comment.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(
                customerId: customer['id']?.toString() ?? '',
                customerName: customer['fullName'] ?? '',
                customerPhone: customer['phone'] ?? '',
              ),
            ),
          );
          // Qaytganidan keyin refresh qilish
          if (mounted) {
            print('🔄 CustomerDetail returned, refreshing customers...');
            context.read<CustomersBloc>().add(const GetCustomersEvent());
          }
        },
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hasDebt
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
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
              if (hasComment)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          isThreeLine: hasComment ? true : false,
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
      ),
    );
  }
}
