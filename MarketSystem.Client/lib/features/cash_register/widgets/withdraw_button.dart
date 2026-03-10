import 'package:flutter/material.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isWithdrawing ? null : onTap,
        icon: isWithdrawing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.arrow_circle_up_outlined),
        label: Text(
          isWithdrawing ? l10n.waiting : label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.danger,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
