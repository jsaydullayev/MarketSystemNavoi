import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/customer_service.dart';
import 'package:market_system_client/data/services/sales_service.dart';

class CustomerSelectionDialog extends StatelessWidget {
  final String saleId;
  final VoidCallback onCustomerSelected;

  const CustomerSelectionDialog({
    super.key,
    required this.saleId,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Bu dialog async data yuklashi kerak, shuning uchun FutureBuilder ishlatamiz
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerService = CustomerService(authProvider: authProvider);

    return FutureBuilder(
      future: customerService.getAllCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Xatolik'),
            content: Text('${snapshot.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yopish'),
              ),
            ],
          );
        }

        final customersData = snapshot.data ?? [];

        return AlertDialog(
          title: const Text('Mijoz tanlang'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: customersData.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Mijozlar topilmadi',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: customersData.length,
                    itemBuilder: (context, index) {
                      final customer = customersData[index];
                      final customerName = customer['fullName'] ?? 'Noma\'lum';
                      final customerPhone = customer['phone'] ?? '';
                      final customerId = customer['id']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child:
                                Icon(Icons.person, color: Colors.blue.shade700),
                          ),
                          title: Text(customerName),
                          subtitle: Text(customerPhone),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              final salesService =
                                  SalesService(authProvider: authProvider);
                              await salesService.updateSaleCustomer(
                                saleId: saleId,
                                customerId: customerId,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('✅ Mijoz qo\'shildi: $customerName'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              onCustomerSelected();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Xatolik: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            // Mijozni olib tashlash
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final salesService = SalesService(authProvider: authProvider);
                  await salesService.updateSaleCustomer(
                    saleId: saleId,
                    customerId: null,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Mijoz olib tashlandi'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  onCustomerSelected();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Xatolik: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Mijozni olib tashlash',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
          ],
        );
      },
    );
  }
}
