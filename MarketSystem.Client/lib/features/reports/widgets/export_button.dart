import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// "Excel'ga yuklash" trigger shown at the bottom of every report tab.
///
/// Demo reference: outline-style action button in `id="page-rpt-hub"` —
/// success-tinted outline that asks before taking the heavy action. We
/// keep it as an `OutlinedButton.icon` rather than swapping to
/// `AppPrimaryButton` so the page's heavy "submit" action isn't the export.
class ExportButton extends StatelessWidget {
  final VoidCallback onTap;

  const ExportButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: Text(
          l10n.downloadExcel,
          style: AppTextStyles.labelLarge().copyWith(color: AppColors.success),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg + 1),
          foregroundColor: AppColors.success,
          side: const BorderSide(color: AppColors.success, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
    );
  }
}
