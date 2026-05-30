import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared status → colour / label helpers for the sales screen widgets.
///
/// Kept in one place so the filter chips, the row status badge and the row
/// icon all read the same colour and name for each status.
class SalesStatusHelpers {
  const SalesStatusHelpers._();

  /// Canonical status → colour. Used by the filter chips, the row status
  /// badge and the row icon so each status reads the same colour everywhere:
  /// in-progress = amber, paid = green, closed = indigo, debt = red.
  static Color getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'draft': // "Davom etayotgan" — sale still in progress
        return AppColors.warning;
      case 'paid':
        return AppColors.success;
      case 'closed':
        return AppColors.darkPrimary;
      case 'debt':
        return AppColors.danger;
      case 'cancelled':
        return context.colors.textMuted;
      default: // 'all' and any unknown status
        return context.colors.brand;
    }
  }

  static String getStatusName(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'draft':
        // User-facing label = "Davom etayotgan" / "В процессе".
        // Backend keeps `Draft` for the enum.
        return l10n.ongoing;
      case 'paid':
        return l10n.paid;
      case 'closed':
        return l10n.closed;
      case 'debt':
        return l10n.debt;
      default:
        return status;
    }
  }
}
