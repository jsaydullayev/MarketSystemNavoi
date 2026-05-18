import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerService = CustomerService(authProvider: authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl2),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.xl3,
      ),
      child: FutureBuilder(
        future: customerService.getAllCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 400,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.error, style: AppTextStyles.titleMedium()),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${snapshot.error}',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  AppSecondaryButton(
                    label: l10n.closed,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }

          final customersData = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        color: AppColors.brand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        l10n.selectCustomer,
                        style: AppTextStyles.titleMedium(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 400,
                  height: 360,
                  child: customersData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                l10n.noCustomersFound,
                                style: AppTextStyles.bodyMedium().copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: customersData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final customer = customersData[index];
                            final customerName =
                                customer['fullName'] ?? l10n.unknown;
                            final customerPhone = customer['phone'] ?? '';
                            final customerId =
                                customer['id']?.toString() ?? '';
                            final debt = (customer['totalDebt'] ??
                                    customer['debt'] ??
                                    0)
                                .toString();

                            return Material(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    final salesService = SalesService(
                                        authProvider: authProvider);
                                    await salesService.updateSaleCustomer(
                                      saleId: saleId,
                                      customerId: customerId,
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${l10n.customerAdded}: $customerName'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                    onCustomerSelected();
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('${l10n.error}: $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.lg),
                                    border: Border.all(
                                      color: AppColors.borderSoft,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: AppColors.inputFill,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _initials(customerName),
                                          style: AppTextStyles.labelLarge()
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customerName,
                                              style: AppTextStyles
                                                  .bodyLarge()
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (customerPhone
                                                .toString()
                                                .isNotEmpty) ...[
                                              const SizedBox(
                                                  height: AppSpacing.xs),
                                              Text(
                                                customerPhone,
                                                style: AppTextStyles
                                                    .bodySmall(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (debt != '0' && debt.isNotEmpty)
                                        Text(
                                          debt,
                                          style: AppTextStyles.labelLarge()
                                              .copyWith(
                                            color: AppColors.brand,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppDangerButton(
                        label: l10n.removeCustomer,
                        onPressed: () async {
                          Navigator.pop(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final salesService =
                                SalesService(authProvider: authProvider);
                            await salesService.updateSaleCustomer(
                              saleId: saleId,
                              customerId: null,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.customerRemoved),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            onCustomerSelected();
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${l10n.error}: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppSecondaryButton(
                        label: l10n.cancel,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
