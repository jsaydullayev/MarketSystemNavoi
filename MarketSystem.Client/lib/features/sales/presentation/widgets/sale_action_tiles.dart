import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';

class SaleActionTiles extends StatelessWidget {
  const SaleActionTiles({super.key, required this.onDownloadPdf});

  final VoidCallback onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _tile(
            context,
            icon: Icons.print_outlined,
            label: l10n.printAction,
            onTap: onDownloadPdf,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _tile(
            context,
            icon: Icons.sms_outlined,
            label: l10n.sendSms,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.comingSoon),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            children: [
              Icon(icon, color: context.colors.brand, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge().copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
