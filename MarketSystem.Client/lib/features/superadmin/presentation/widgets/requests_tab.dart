import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/registration_request.dart';
import 'console_shared_widgets.dart';
import 'request_card.dart';

class RequestsTab extends StatelessWidget {
  const RequestsTab({
    super.key,
    required this.loading,
    required this.error,
    required this.items,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  final bool loading;
  final String? error;
  final List<RegistrationRequest>? items;
  final Future<void> Function() onRefresh;
  final Future<void> Function(RegistrationRequest) onApprove;
  final Future<void> Function(RegistrationRequest) onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.brand),
      );
    }
    if (error case final err?) {
      return ConsoleErrorState(error: err, onRetry: onRefresh);
    }
    final list = items ?? const <RegistrationRequest>[];

    return RefreshIndicator(
      color: context.colors.brand,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats row — counts come from the live list; "approved/rejected
            // this month" require a server-side aggregate we don't surface yet.
            LayoutBuilder(
              builder: (ctx, c) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: c.maxWidth < 600 ? 1 : 3,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: c.maxWidth < 600 ? 4 : 2.2,
                children: [
                  MiniStatCard(
                    label: l10n.superAdminPending.toUpperCase(),
                    value: list.length.toString(),
                    color: AppColors.warning,
                    subtitle: l10n.superAdminNewRequests,
                  ),
                  MiniStatCard(
                    label: l10n.superAdminApproved,
                    value: '—',
                    color: AppColors.success,
                    subtitle: l10n.superAdminServerStatsNeeded,
                  ),
                  MiniStatCard(
                    label: l10n.superAdminRejected,
                    value: '—',
                    color: AppColors.danger,
                    subtitle: l10n.superAdminServerStatsNeeded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.superAdminPendingRequestsHeader,
                    style: AppTextStyles.caption().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                RefreshChip(onRefresh: onRefresh),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (list.isEmpty)
              ConsoleEmptyState(
                icon: Icons.assignment_outlined,
                text: l10n.superAdminNoPendingRequests,
              )
            else
              ...list.map(
                (req) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: RequestCard(
                    request: req,
                    onApprove: () => onApprove(req),
                    onReject: () => onReject(req),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl3),
          ],
        ),
      ),
    );
  }
}
