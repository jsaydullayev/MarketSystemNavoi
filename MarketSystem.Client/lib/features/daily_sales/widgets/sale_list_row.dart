import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/data/models/profit_model.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

/// Compact one-row sale entry (Variant A timeline). Replaces the old square
/// grid card so 10+ sales/day stay scannable. Tapping opens the detail sheet
/// (handled by the parent screen via `onTap`).
class SaleListRow extends StatelessWidget {
  final DailySalesListItemModel sale;
  final VoidCallback onTap;

  const SaleListRow({super.key, required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, sale.status);
    final customerName = (sale.customerName ?? '').trim();
    final hasCustomer = customerName.isNotEmpty;

    // Refunded / cancelled rows are dimmed so they read as "done, but not
    // a contributing sale" — matches the demo's `.sale-row.refunded` styling.
    final isCancelled = sale.status.toLowerCase() == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Opacity(
            opacity: isCancelled ? 0.65 : 1,
            child: Ink(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.border),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  _TimeBadge(time: sale.createdAt),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _CustomerAvatar(
                              name: hasCustomer ? customerName : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hasCustomer ? customerName : '—',
                                style: AppTextStyles.bodySmall().copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt(sale.totalAmount)} so\'m',
                          style: AppTextStyles.labelLarge().copyWith(
                            fontSize: 15,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatusChip(status: sale.status, color: statusColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'debt':
        return AppColors.warning;
      case 'closed':
        return const Color(0xFF6366F1);
      case 'cancelled':
        return AppColors.danger;
      default:
        return context.colors.textMuted;
    }
  }

  String _fmt(double n) {
    return NumberFormat('#,###', 'en_US').format(n).replaceAll(',', ' ');
  }
}

class _TimeBadge extends StatelessWidget {
  final DateTime time;
  const _TimeBadge({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(time),
            style: AppTextStyles.labelLarge().copyWith(
              fontSize: 13,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final String? name;
  const _CustomerAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.isNotEmpty;
    final initial = hasName ? name!.trim()[0].toUpperCase() : '?';
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasName ? AppColors.brandTint : context.colors.inputFill,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.caption().copyWith(
          fontSize: 10,
          color: hasName ? context.colors.brandDark : context.colors.textMuted,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption().copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}
