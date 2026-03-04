import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onTap;

  const ExportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: Text(l10n.downloadExcel),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
