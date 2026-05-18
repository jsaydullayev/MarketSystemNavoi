// Debtor detail screen — mirrors "8.2 Mijoz detali" from the HTML demo:
//   * Hero card: palette avatar + name + phone + 3 stats (sotuvlar / qarz /
//     oxirgi).
//   * Quick actions: 💰 Qarz to'lov qabul (primary) + 📱 SMS (secondary).
//   * Qarz tarixi list: each sale becomes one debit "ledger" card; line
//     items inside the card keep the legacy "Narxni o'zgartirish" affordance
//     because the price-edit flow is wired to SalesService.updateSaleItemPrice
//     and must survive the migration.
//
// All business logic from the legacy implementation is preserved:
//   * The screen accepts the same constructor params (customerId, customerName,
//     debtorData) so call sites compile unchanged.
//   * Tapping "Narxni o'zgartirish" still calls
//     SalesService.updateSaleItemPrice with the same payload and validation
//     ("priceMustBePositive", optional comment defaulting to l10n.priceUpdated).
//   * Pressing "Qarz to'lov" opens DebtorPaymentSheet with the legacy
//     widget.debtorData['sales'] payload, so the existing API hook still fires.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import '../widgets/debtor_payment_dialog.dart';

class DebtorDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final Map<String, dynamic> debtorData;

  const DebtorDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.debtorData,
  });

  @override
  State<DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<DebtorDetailScreen> {
  bool _isLoading = false;

  Future<void> _showPriceChangeDialog(
      dynamic saleItem, String saleId) async {
    final l10n = AppLocalizations.of(context)!;
    final itemId = saleItem['id'];
    final productName = saleItem['productName'];
    final currentPrice =
        (saleItem['salePrice'] as num?)?.toDouble() ?? 0.0;
    final quantity = (saleItem['quantity'] as num?)?.toDouble() ?? 0.0;

    final priceController =
        TextEditingController(text: currentPrice.toString());
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double newPrice = currentPrice;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl)),
            backgroundColor: AppColors.surface,
            title: Text(
              '${l10n.changePrice}: $productName',
              style: AppTextStyles.titleMedium(),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.currentPrice,
                            style: AppTextStyles.bodyMedium()),
                        Text(
                          NumberFormatter.formatDecimal(currentPrice),
                          style: AppTextStyles.labelLarge(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.bodyMedium(),
                    decoration: InputDecoration(
                      labelText: l10n.newPriceLabel,
                      prefixIcon: const Icon(Icons.attach_money_rounded,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md + 2),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md + 2),
                        borderSide: const BorderSide(
                            color: AppColors.brand, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        newPrice =
                            double.tryParse(value) ?? currentPrice;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius:
                          BorderRadius.circular(AppRadius.md + 2),
                      border: Border.all(
                          color: AppColors.warning
                              .withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${l10n.total}: ${NumberFormatter.formatDecimal(newPrice * quantity)} ${l10n.currencySom}',
                                style: AppTextStyles.bodyMedium().copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.quantityCount(quantity),
                          style: AppTextStyles.bodySmall().copyWith(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    style: AppTextStyles.bodyMedium(),
                    decoration: InputDecoration(
                      labelText: l10n.commentOptional,
                      prefixIcon: const Icon(Icons.comment_outlined,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md + 2),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md + 2),
                        borderSide: const BorderSide(
                            color: AppColors.brand, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel,
                    style: AppTextStyles.bodyMedium()
                        .copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (newPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.priceMustBePositive),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(dialogContext);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false);
                        try {
                          setState(() => _isLoading = true);
                          final salesService =
                              SalesService(authProvider: authProvider);
                          await salesService.updateSaleItemPrice(
                            saleItemId: itemId,
                            newPrice: newPrice,
                            comment:
                                commentController.text.trim().isEmpty
                                    ? l10n.priceUpdated
                                    : commentController.text.trim(),
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    l10n.priceChangedFor(productName)),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            nav.pop(true);
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${l10n.error}: $e'),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.brand),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    priceController.dispose();
    commentController.dispose();
  }

  void _onOpenPaymentSheet() {
    final sales = widget.debtorData['sales'] as List<dynamic>? ?? const [];
    showDebtorPaymentSheet(
      context,
      debtor: widget.debtorData,
      debtSales: sales,
      onPaymentSuccess: () {
        // The list screen reloads on focus; pop back so it shows fresh data.
        Navigator.of(context).maybePop();
      },
    );
  }

  void _onSendSms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS eslatma — tez kunda'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sales = widget.debtorData['sales'] as List<dynamic>? ?? const [];
    final remainingDebt =
        (widget.debtorData['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final lastActivity = _resolveLastActivity(sales);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: CommonAppBar(title: widget.customerName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl3),
              children: [
                _CustomerHero(
                  name: widget.customerName,
                  phone:
                      widget.debtorData['customerPhone'] as String? ?? '',
                  salesCount: sales.length,
                  remainingDebt: remainingDebt,
                  lastActivity: lastActivity,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: l10n.payDebt,
                        onPressed: remainingDebt > 0
                            ? _onOpenPaymentSheet
                            : null,
                        icon: Icons.payments_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md + 2),
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'SMS eslatma',
                        onPressed: _onSendSms,
                        icon: Icons.sms_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.debtHistory,
                        style: AppTextStyles.titleMedium()),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md + 2,
                          vertical: AppSpacing.xs + 1),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        '${sales.length} ta',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.brand,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (sales.isEmpty)
                  _EmptySales()
                else
                  ...sales.map((sale) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _SaleLedgerCard(
                          sale: sale,
                          onPriceEdit: _showPriceChangeDialog,
                        ),
                      )),
              ],
            ),
    );
  }

  String? _resolveLastActivity(List<dynamic> sales) {
    DateTime? latest;
    for (final s in sales) {
      final raw = s['createdAt'];
      if (raw == null) continue;
      try {
        final parsed =
            raw is DateTime ? raw : DateTime.parse(raw.toString());
        if (latest == null || parsed.isAfter(latest)) latest = parsed;
      } catch (_) {}
    }
    if (latest == null) return null;
    return NumberFormatter.formatDateTime(latest, showTime: false);
  }
}

/// White hero card with a palette avatar and 3 stat columns.
class _CustomerHero extends StatelessWidget {
  const _CustomerHero({
    required this.name,
    required this.phone,
    required this.salesCount,
    required this.remainingDebt,
    required this.lastActivity,
  });

  final String name;
  final String phone;
  final int salesCount;
  final double remainingDebt;
  final String? lastActivity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayLabel = name.isNotEmpty ? name : phone;
    final color = CustomerAvatarPalette.pick(displayLabel);
    final initial = displayLabel.isNotEmpty
        ? displayLabel.characters.first.toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.displayMedium().copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            name,
            style: AppTextStyles.titleMedium(),
            textAlign: TextAlign.center,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  phone,
                  style: AppTextStyles.bodySmall()
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: '$salesCount',
                  label: l10n.sales.toUpperCase(),
                ),
              ),
              const _Divider(),
              Expanded(
                child: _HeroStat(
                  value: NumberFormatter.format(remainingDebt),
                  label: l10n.debt.toUpperCase(),
                  highlight: remainingDebt > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
              const _Divider(),
              Expanded(
                child: _HeroStat(
                  value: lastActivity ?? '—',
                  label: 'OXIRGI',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label, this.highlight});
  final String value;
  final String label;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          child: Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              color: highlight ?? AppColors.text,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: AppColors.border,
      );
}

/// A single sale rendered as a "qarz tarixi" card. The header is a debit-style
/// row (down-arrow icon + sana / chek + qarz amount). Items show below with
/// the "Narxni o'zgartirish" affordance.
class _SaleLedgerCard extends StatelessWidget {
  const _SaleLedgerCard({required this.sale, required this.onPriceEdit});
  final dynamic sale;
  final void Function(dynamic saleItem, String saleId) onPriceEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = sale['items'] as List<dynamic>? ?? const [];
    final saleId = sale['id']?.toString() ?? '';
    final saleDate = sale['createdAt'];
    final saleRemaining =
        (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    final formattedDate =
        NumberFormatter.formatDateTime(saleDate, showTime: true);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ledger-style header: down arrow icon + qarzga olindi + amount.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
            decoration: const BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qarzga olindi',
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${NumberFormatter.formatDecimal(saleRemaining)}',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColors.danger,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Items
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: _ItemRow(
                item: items[i],
                onEdit: () => onPriceEdit(items[i], saleId),
                unknownLabel: l10n.unknown,
                changePriceLabel: l10n.changePrice,
              ),
            ),
            if (i != items.length - 1)
              Container(height: 1, color: AppColors.borderSoft),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onEdit,
    required this.unknownLabel,
    required this.changePriceLabel,
  });
  final dynamic item;
  final VoidCallback onEdit;
  final String unknownLabel;
  final String changePriceLabel;

  @override
  Widget build(BuildContext context) {
    final name = item['productName'] ?? unknownLabel;
    final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final total = price * qty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyMedium()
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$qty × ${NumberFormatter.format(price)}',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormatter.formatDecimal(total),
              style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 12, color: AppColors.brand),
                    const SizedBox(width: 4),
                    Text(
                      changePriceLabel,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.brand,
                        fontSize: 10,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySales extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            decoration: const BoxDecoration(
              color: AppColors.borderSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.noSales, style: AppTextStyles.titleMedium()),
        ],
      ),
    );
  }
}
