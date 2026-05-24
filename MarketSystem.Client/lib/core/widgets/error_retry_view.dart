import 'package:flutter/material.dart';

import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_button.dart';
import '../../l10n/app_localizations.dart';

/// D1 — shared "we couldn't load this — try again" view.
///
/// The audit found that Dashboard / Notifications / Sales / Debts all
/// caught load errors and silently rendered an empty state — backend
/// outages looked identical to "no data yet". This widget gives every
/// list/detail screen a consistent fallback: a danger-tinted icon,
/// a localized headline, an optional second line carrying the server
/// message, and a primary Retry button wired to the screen's reload.
///
/// Usage:
/// ```
/// // In a FutureBuilder:
/// if (snapshot.hasError) {
///   return ErrorRetryView(onRetry: _refresh);
/// }
///
/// // In a BlocBuilder:
/// if (state is SalesError) {
///   return ErrorRetryView(
///     message: state.message,
///     onRetry: () => context.read<SalesBloc>().add(const GetSalesEvent()),
///   );
/// }
/// ```
///
/// Use [scrollable] = true (the default) when the parent is inside a
/// RefreshIndicator — the AlwaysScrollable physics lets the user
/// pull-to-refresh even with a single error card on screen.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    this.message,
    required this.onRetry,
    this.scrollable = true,
  });

  /// Server-side message (e.g. ApiException.message). Localized by the
  /// backend already — safe to render verbatim. Falls back to a generic
  /// localized "Xatolik yuz berdi" when null/empty.
  final String? message;

  final VoidCallback onRetry;

  /// When true (default), wraps in a scrollable so a parent
  /// RefreshIndicator still works. Set to false inside a Column /
  /// Sliver where the scroll behaviour is owned upstream.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.loadFailedTitle,
              style: AppTextStyles.titleMedium().copyWith(
                color: context.colors.text,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              (message != null && message!.isNotEmpty)
                  ? message!
                  : l10n.loadFailedDescription,
              style: AppTextStyles.bodySmall().copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
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

    if (!scrollable) return body;

    // ListView (not SingleChildScrollView) so AlwaysScrollable
    // composes naturally with a parent RefreshIndicator.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.6, child: body),
      ],
    );
  }
}
