import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class EmptyReport extends StatelessWidget {
  const EmptyReport();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            l10n.noReports,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
