import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerService = CustomerService(authProvider: authProvider);
    final l10n = AppLocalizations.of(context)!;

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
            title: Text(l10n.error),
            content: Text('${snapshot.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.closed),
              ),
            ],
          );
        }

        final customersData = snapshot.data ?? [];

        return AlertDialog(
          title: Text(l10n.selectCustomer),
          content: SizedBox(
            width: 400,
            height: 400,
            child: customersData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.noCustomersFound,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: customersData.length,
                    itemBuilder: (context, index) {
                      final customer = customersData[index];
                      final customerName = customer['fullName'] ?? l10n.unknown;
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
                                  content: Text(
                                      '${l10n.customerAdded}: $customerName'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              onCustomerSelected();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${l10n.error}: $e'),
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
                    SnackBar(
                      content: Text(l10n.customerRemoved),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  onCustomerSelected();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(l10n.removeCustomer,
                  style: const TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}
