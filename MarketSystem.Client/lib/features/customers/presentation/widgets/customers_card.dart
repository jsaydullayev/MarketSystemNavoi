import 'package:flutter/material.dart';
import 'package:market_system_client/core/providers/auth_provider.dart'
    as core_auth;
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/data/services/customer_service.dart';
import 'package:market_system_client/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:market_system_client/features/customers/presentation/bloc/events/customers_event.dart';
import 'package:market_system_client/features/customers/presentation/screens/customer_detail_screen.dart';

class CustomersCard extends StatelessWidget {
  final dynamic customer;
  const CustomersCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final totalDebt = (customer['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final hasDebt = totalDebt > 0;
    final comment = customer['comment']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = customer['fullName']?.toString() ?? '';
    final phone = customer['phone']?.toString() ?? '';
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : phone.isNotEmpty
            ? phone[0]
            : '?';
    final color = hasDebt ? Colors.red : Colors.green;
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key('customer_${customer['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_forever_rounded,
                color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(l10n.delete,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(context);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDebt
                ? Colors.red.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(
                  customerId: customer['id']?.toString() ?? '',
                  customerName: name,
                  customerPhone: phone,
                ),
              ),
            );
            if (context.mounted) {
              context.read<CustomersBloc>().add(const GetCustomersEvent());
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : phone,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.comment_rounded,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                comment,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _showInfoSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline_rounded,
                            size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        hasDebt
                            ? NumberFormatter.format(totalDebt)
                            : l10n.noDebt,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<core_auth.AuthProvider>();
    final customerService = CustomerService(authProvider: authProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final deleteInfo =
          await customerService.getCustomerDeleteInfo(customer['id']);
      if (context.mounted) Navigator.pop(context);

      if (!context.mounted) return false;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.deleteCustomer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '${customer['fullName'] ?? customer['phone']} ${l10n.deleteCustomerConfirm(customer['fullName'] ?? customer['phone'])}'),
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
                child: Text(l10n.no)),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.yesDelete),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        context.read<CustomersBloc>().add(DeleteCustomerEvent(customer['id']));
      }
      return false;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      context.read<CustomersBloc>().add(DeleteCustomerEvent(customer['id']));
      return false;
    }
  }

  void _showInfoSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalDebt = (customer['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final hasDebt = totalDebt > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _InfoRow(
                icon: Icons.person_rounded,
                label: l10n.fullName,
                value: customer['fullName'] ?? l10n.unknown),
            _InfoRow(
                icon: Icons.phone_rounded,
                label: l10n.phoneNumber,
                value: customer['phone'] ?? l10n.unknown),
            _InfoRow(
              icon: Icons.monetization_on_rounded,
              label: l10n.debt,
              value: hasDebt ? NumberFormatter.format(totalDebt) : l10n.noDebt,
              valueColor: hasDebt ? Colors.red : Colors.green,
            ),
            if ((customer['comment']?.toString() ?? '').isNotEmpty)
              _InfoRow(
                  icon: Icons.comment_rounded,
                  label: l10n.comment,
                  value: customer['comment']),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: valueColor)),
        ],
      ),
    );
  }
}
