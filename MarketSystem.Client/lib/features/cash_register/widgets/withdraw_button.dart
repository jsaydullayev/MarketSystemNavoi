import 'package:flutter/material.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// "Withdraw cash" primary action button. Uses the danger variant from the
/// design system because this is a destructive money movement.
class WithdrawButton extends StatelessWidget {
  final bool isWithdrawing;
  final VoidCallback onTap;
  final String label;

  const WithdrawButton({
    super.key,
    required this.isWithdrawing,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppDangerButton(
      label: isWithdrawing ? l10n.waiting : label,
      icon: Icons.arrow_circle_up_outlined,
      isLoading: isWithdrawing,
      onPressed: isWithdrawing ? null : onTap,
    );
  }
}
