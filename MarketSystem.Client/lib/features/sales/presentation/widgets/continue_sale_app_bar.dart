import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/sales/presentation/widgets/continue_sale_header_widgets.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Custom POS-style header — back button + title with chek# meta on the
/// left, customer chip on the right. Mirrors `NewSaleScreen` so the
/// "continue" experience visually picks up where "new" left off.
class ContinueSaleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContinueSaleAppBar({
    super.key,
    required this.sale,
    required this.selectedCustomer,
    required this.l10n,
    required this.onBack,
    required this.onCustomerTap,
  });

  final Map<String, dynamic>? sale;
  final Map<String, dynamic>? selectedCustomer;
  final AppLocalizations l10n;
  final VoidCallback onBack;
  final VoidCallback onCustomerTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            bottom: BorderSide(color: context.colors.borderSoft, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                ContinueSalePosBackButton(onTap: onBack),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.draftSale,
                        style: AppTextStyles.labelLarge().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _headerMeta(),
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: context.colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ContinueSaleCustomerChip(
                  customer: selectedCustomer,
                  fallbackLabel: l10n.customerNotSelected,
                  enabled: sale == null ? false : sale?['status'] != 'Closed',
                  onTap: onCustomerTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Meta line under the title — receipt number from the sale + a stable
  /// time slug. Receipt number falls back to the saleId prefix when the
  /// API hasn't surfaced one.
  String _headerMeta() {
    final receipt = (sale?['receiptNumber'] ?? sale?['number'] ?? '')
        .toString();
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (receipt.isNotEmpty) return 'Chek #$receipt · $hh:$mm';
    return 'Chek · $hh:$mm';
  }
}
