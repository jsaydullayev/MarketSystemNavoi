import 'package:flutter/material.dart';
import 'package:market_system_client/core/providers/auth_provider.dart'
    as core_auth;
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/services/customer_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:market_system_client/features/customers/presentation/bloc/events/customers_event.dart';
import 'package:market_system_client/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CustomersCard extends StatelessWidget {
  final dynamic customer;
  const CustomersCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalDebt = (customer['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final hasDebt = totalDebt > 0;
    final comment = customer['comment']?.toString() ?? '';
    final name = customer['fullName']?.toString() ?? '';
    final phone = customer['phone']?.toString() ?? '';
    final displayLabel = name.isNotEmpty ? name : phone;
    final initial = displayLabel.isNotEmpty
        ? displayLabel.characters.first.toUpperCase()
        : '?';
    final avatarColor = CustomerAvatarPalette.pick(displayLabel);

    return Dismissible(
      key: Key('customer_${customer['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl2),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_forever_rounded,
                color: Colors.white, size: 26),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.delete,
              style: AppTextStyles.caption().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(context);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.border),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg + 2,
                vertical: AppSpacing.lg + 2,
              ),
              child: Row(
                children: [
                  _Avatar(initial: initial, color: avatarColor),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayLabel,
                          style: AppTextStyles.labelLarge(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          phone,
                          style: AppTextStyles.bodySmall().copyWith(
                            fontSize: 12,
                            color: context.colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            comment,
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 11,
                              color: context.colors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showInfoSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.colors.inputFill,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md - 2),
                          ),
                          child: Icon(Icons.info_outline_rounded,
                              size: 18, color: context.colors.textMuted),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DebtBadge(hasDebt: hasDebt, totalDebt: totalDebt),
                    ],
                  ),
                ],
              ),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text(l10n.deleteCustomer, style: AppTextStyles.titleMedium()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${customer['fullName'] ?? customer['phone']} ${l10n.deleteCustomerConfirm(customer['fullName'] ?? customer['phone'])}',
                style: AppTextStyles.bodyMedium(),
              ),
              if (deleteInfo['warningMessage'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text(
                    deleteInfo['warningMessage'],
                    style: AppTextStyles.bodySmall()
                        .copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.no),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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
      // Fail-closed: if we can't fetch the delete-info preview, fall back to a
      // plain confirmation dialog. NEVER auto-delete on error — the previous
      // code did, which meant any network / API hiccup destroyed customer rows
      // without a single confirmation prompt.
      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return false;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text(l10n.deleteCustomer, style: AppTextStyles.titleMedium()),
          content: Text(
            '${customer['fullName'] ?? customer['phone']} ${l10n.deleteCustomerConfirm(customer['fullName'] ?? customer['phone'])}',
            style: AppTextStyles.bodyMedium(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.no),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(l10n.yesDelete),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        context.read<CustomersBloc>().add(DeleteCustomerEvent(customer['id']));
      }
      return false;
    }
  }

  void _showInfoSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalDebt = (customer['totalDebt'] as num?)?.toDouble() ?? 0.0;
    final hasDebt = totalDebt > 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
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
              value:
                  hasDebt ? NumberFormatter.format(totalDebt) : l10n.noDebt,
              valueColor: hasDebt ? AppColors.danger : AppColors.success,
            ),
            if ((customer['comment']?.toString() ?? '').isNotEmpty)
              _InfoRow(
                  icon: Icons.comment_rounded,
                  label: l10n.comment,
                  value: customer['comment']),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.color});
  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.labelLarge().copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DebtBadge extends StatelessWidget {
  const _DebtBadge({required this.hasDebt, required this.totalDebt});
  final bool hasDebt;
  final double totalDebt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = hasDebt ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
      ),
      child: Text(
        hasDebt ? NumberFormatter.format(totalDebt) : l10n.noDebt,
        style: AppTextStyles.bodyMedium().copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.textMuted),
          const SizedBox(width: AppSpacing.lg),
          Text(label,
              style: AppTextStyles.bodyMedium()
                  .copyWith(color: context.colors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? context.colors.text,
            ),
          ),
        ],
      ),
    );
  }
}
