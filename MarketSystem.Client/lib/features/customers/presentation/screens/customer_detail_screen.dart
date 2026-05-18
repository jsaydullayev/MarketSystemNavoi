import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/features/customers/presentation/widgets/debt_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import '../bloc/customers_bloc.dart';
import '../bloc/events/customers_event.dart';
import '../bloc/states/customers_state.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(GetCustomerDebtsEvent(widget.customerId));
  }

  String get _displayLabel => widget.customerName.isNotEmpty
      ? widget.customerName
      : widget.customerPhone;

  @override
  Widget build(BuildContext context) {
    return NetworkWrapper(
      onRetry: () => context
          .read<CustomersBloc>()
          .add(GetCustomerDebtsEvent(widget.customerId)),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: CommonAppBar(
          title: _displayLabel,
          onRefresh: () => context
              .read<CustomersBloc>()
              .add(GetCustomerDebtsEvent(widget.customerId)),
        ),
        body: BlocConsumer<CustomersBloc, CustomersState>(
          listener: (context, state) {
            if (state is CustomersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                  margin: const EdgeInsets.all(AppSpacing.xl),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CustomerDebtsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CustomerDebtsLoaded) {
              return _buildDebtsList(state.debts);
            } else if (state is CustomersError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context
                    .read<CustomersBloc>()
                    .add(GetCustomerDebtsEvent(widget.customerId)),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildDebtsList(List<Map<String, dynamic>> debts) {
    final l10n = AppLocalizations.of(context)!;

    if (debts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => context
            .read<CustomersBloc>()
            .add(GetCustomerDebtsEvent(widget.customerId)),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _CustomerHero(
              name: widget.customerName,
              phone: widget.customerPhone,
              salesCount: 0,
              totalDebt: 0,
              lastActivity: null,
            ),
            const SizedBox(height: AppSpacing.xl),
            _EmptyDebtsView(displayLabel: _displayLabel),
          ],
        ),
      );
    }

    final totalRemainingDebt = debts.fold<double>(
      0,
      (sum, debt) =>
          sum + ((debt['remainingDebt'] as num?)?.toDouble() ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () async => context
          .read<CustomersBloc>()
          .add(GetCustomerDebtsEvent(widget.customerId)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl4),
        children: [
          _CustomerHero(
            name: widget.customerName,
            phone: widget.customerPhone,
            salesCount: debts.length,
            totalDebt: totalRemainingDebt,
            lastActivity: _resolveLastActivity(debts),
          ),
          const SizedBox(height: AppSpacing.xl),
          _QuickActions(
            onPay: totalRemainingDebt > 0 ? _onPay : null,
            onSms: _onSendSms,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.debtHistory, style: AppTextStyles.titleMedium()),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 2,
                    vertical: AppSpacing.xs + 1),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '${debts.length} ta',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.brand,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...debts.map((debt) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: DebtCard(debt: debt),
              )),
        ],
      ),
    );
  }

  String? _resolveLastActivity(List<Map<String, dynamic>> debts) {
    DateTime? latest;
    for (final d in debts) {
      final raw = d['createdAt'];
      if (raw == null) continue;
      try {
        final parsed = raw is DateTime ? raw : DateTime.parse(raw.toString());
        if (latest == null || parsed.isAfter(latest)) latest = parsed;
      } catch (_) {
        // ignore unparseable values
      }
    }
    if (latest == null) return null;
    return NumberFormatter.formatDateTime(latest, showTime: false);
  }

  void _onPay() {
    // The pay sheet lives on the debts feature; for the detail screen we
    // surface the action but routing into the existing flow is left to the
    // caller (debts_screen handles it). When called here we open a simple
    // hint snackbar — wiring deeper would require importing the debts feature
    // and crossing layer boundaries we don't want from customers.
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.payDebt),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSendSms() {
    // Placeholder — kept as a no-op so the button has the same visual weight
    // as the demo. The SMS reminder feature is a separate ticket.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS eslatma — tez kunda'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({
    required this.name,
    required this.phone,
    required this.salesCount,
    required this.totalDebt,
    required this.lastActivity,
  });

  final String name;
  final String phone;
  final int salesCount;
  final double totalDebt;
  final String? lastActivity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayLabel = name.isNotEmpty ? name : phone;
    final initial = displayLabel.isNotEmpty
        ? displayLabel.characters.first.toUpperCase()
        : '?';
    final avatarColor = CustomerAvatarPalette.pick(displayLabel);

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
                BoxDecoration(color: avatarColor, shape: BoxShape.circle),
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
          if (name.isNotEmpty)
            Text(
              name,
              style: AppTextStyles.titleMedium(),
              textAlign: TextAlign.center,
            ),
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
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: '$salesCount',
                  label: l10n.sales,
                ),
              ),
              _Divider(),
              Expanded(
                child: _HeroStat(
                  value: NumberFormatter.format(totalDebt),
                  label: l10n.debt,
                  highlight: totalDebt > 0 ? AppColors.warning : null,
                ),
              ),
              _Divider(),
              Expanded(
                child: _HeroStat(
                  value: lastActivity ?? '—',
                  label: 'Oxirgi',
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
          label.toUpperCase(),
          style: AppTextStyles.caption(),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.border);
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onPay, required this.onSms});
  final VoidCallback? onPay;
  final VoidCallback onSms;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: AppPrimaryButton(
            label: l10n.payDebt,
            onPressed: onPay,
            icon: Icons.payments_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AppSecondaryButton(
            label: 'SMS eslatma',
            onPressed: onSms,
            icon: Icons.sms_outlined,
          ),
        ),
      ],
    );
  }
}

class _EmptyDebtsView extends StatelessWidget {
  const _EmptyDebtsView({required this.displayLabel});
  final String displayLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              size: 48, color: AppColors.success),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.noDebts,
          style: AppTextStyles.titleMedium(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          displayLabel,
          style: AppTextStyles.bodySmall(),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(message,
                style: AppTextStyles.bodyMedium()
                    .copyWith(color: AppColors.danger),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: l10n.retry,
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
