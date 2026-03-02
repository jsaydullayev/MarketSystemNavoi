import 'package:flutter/material.dart';
import 'package:market_system_client/core/providers/auth_provider.dart'
    as core_auth;
import 'package:provider/provider.dart'; // Provider qo'shildi
import 'package:market_system_client/data/services/customer_service.dart';
import 'package:market_system_client/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:market_system_client/features/customers/presentation/bloc/events/customers_event.dart';
import 'package:market_system_client/features/customers/presentation/screens/customer_detail_screen.dart';

class CustomersCard extends StatelessWidget {
  final dynamic customer;

  const CustomersCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Ma'lumotlarni olish
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
          if (context.mounted) {
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
            child:
                Icon(Icons.person, color: hasDebt ? Colors.red : Colors.green),
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
              Text(
                hasDebt ? 'Qarz: $totalDebt so\'m' : 'Qarzsiz',
                style: TextStyle(
                  color: hasDebt ? Colors.red : Colors.green,
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
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showCustomerInfo(context, customer),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCustomer(context, customer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteCustomer(BuildContext context, dynamic customer) async {
    // Service-ni to'g'ri initialize qilish
    final authProvider = context.read<core_auth.AuthProvider>();
    final customerService = CustomerService(authProvider: authProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final deleteInfo =
          await customerService.getCustomerDeleteInfo(customer['id']);
      if (context.mounted) Navigator.pop(context); // Loadingni yopish

      if (context.mounted) {
        showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Mijozni o\'chirish'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '${customer['fullName'] ?? customer['phone']} mijozini o\'chirmoqchimisiz?'),
                if (deleteInfo['warningMessage'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(deleteInfo['warningMessage'],
                        style: const TextStyle(color: Colors.orange)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Yo\'q')),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ha, o\'chirish'),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed == true && context.mounted) {
            context
                .read<CustomersBloc>()
                .add(DeleteCustomerEvent(customer['id']));
          }
        });
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Loading yopish
      // Xatolik bo'lsa oddiy o'chirish
      context.read<CustomersBloc>().add(DeleteCustomerEvent(customer['id']));
    }
  }

  void _showCustomerInfo(BuildContext context, dynamic customer) {
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
              child: const Text('Yopish')),
        ],
      ),
    );
  }
}
