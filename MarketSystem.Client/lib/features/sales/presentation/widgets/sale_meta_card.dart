import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class SaleMetaCard extends StatelessWidget {
  const SaleMetaCard({super.key, required this.sale, required this.status});

  final Map<String, dynamic> sale;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(status, context);
    final paymentType = sale['paymentType']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSoft),
      ),
      child: Column(
        children: [
          _row(context, l10n.seller,
              sale['sellerName']?.toString() ?? l10n.unknown,
              context.colors.text),
          _divider(context),
          _row(
            context,
            l10n.dateTimeLabel,
            DateFormat('dd.MM.yyyy HH:mm').format(
              sale['createdAt'] is DateTime
                  ? sale['createdAt'] as DateTime
                  : DateTime.parse(sale['createdAt'].toString()),
            ),
            context.colors.text,
          ),
          if (paymentType != null && paymentType.isNotEmpty) ...[
            _divider(context),
            _row(context, l10n.paymentType, _paymentLabel(paymentType, l10n),
                context.colors.text),
          ],
          if (sale['customerName'] != null) ...[
            _divider(context),
            _row(context, l10n.customer, sale['customerName'].toString(),
                context.colors.text),
          ],
          _divider(context),
          _row(
            context,
            l10n.statusLabel,
            _statusLabel(status, l10n),
            color,
            valueWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color valueColor,
      {FontWeight? valueWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall()
                    .copyWith(color: context.colors.textSecondary)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium().copyWith(
                color: valueColor,
                fontWeight: valueWeight ?? FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
        height: 1,
        color: context.colors.border.withValues(alpha: 0.6),
      );

  static Color _statusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'debt':
        return AppColors.danger;
      case 'draft':
        return AppColors.warning;
      case 'closed':
        return const Color(0xFF6366F1);
      default:
        return context.colors.textMuted;
    }
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'paid':
        return l10n.paid;
      case 'debt':
        return l10n.debt;
      case 'draft':
        return l10n.ongoing;
      case 'closed':
        return l10n.closed;
      default:
        return status;
    }
  }

  static String _paymentLabel(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'cash':
        return l10n.cash;
      case 'card':
        return l10n.card;
      case 'terminal':
        return l10n.terminal;
      case 'debt':
        return l10n.debt;
      default:
        return type;
    }
  }
}
