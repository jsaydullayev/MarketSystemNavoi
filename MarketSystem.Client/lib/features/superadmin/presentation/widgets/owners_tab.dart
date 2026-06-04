import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/owner_summary.dart';
import 'console_shared_widgets.dart';
import 'owner_card.dart';

class OwnersTab extends StatelessWidget {
  const OwnersTab({
    super.key,
    required this.loading,
    required this.error,
    required this.items,
    required this.search,
    required this.searchCtrl,
    required this.onRefresh,
    required this.onTap,
    required this.onCreate,
  });

  final bool loading;
  final String? error;
  final List<OwnerSummary>? items;
  final String search;
  final TextEditingController searchCtrl;
  final Future<void> Function() onRefresh;
  final Future<void> Function(OwnerSummary) onTap;
  final VoidCallback onCreate;

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
    final all = items ?? const <OwnerSummary>[];
    final filtered = search.isEmpty
        ? all
        : all.where((o) {
            final s = search;
            return o.fullName.toLowerCase().contains(s) ||
                o.username.toLowerCase().contains(s) ||
                (o.marketName ?? '').toLowerCase().contains(s) ||
                (o.phone ?? '').toLowerCase().contains(s);
          }).toList();

    return RefreshIndicator(
      color: context.colors.brand,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          96, // FAB clearance
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: context.colors.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: context.colors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.ownerSearchHint,
                        hintStyle: AppTextStyles.bodyMedium().copyWith(
                          color: context.colors.textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                      ),
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: context.colors.textSecondary,
                      onPressed: () => searchCtrl.clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.superAdminActiveOwnersHeader(filtered.length),
                    style: AppTextStyles.caption().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                RefreshChip(onRefresh: onRefresh),
                const SizedBox(width: AppSpacing.md),
                // Adaptive: a full labelled button would crush the header title
                // on narrow phones (and looks stranded on tablets), so collapse
                // to an icon-only add button below ~380dp.
                if (MediaQuery.sizeOf(context).width < AppBreakpoints.compact)
                  IconButton.filled(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    tooltip: l10n.addNew,
                    style: IconButton.styleFrom(
                      backgroundColor: context.colors.brand,
                      foregroundColor: context.colors.onBrand,
                    ),
                  )
                else
                  SizedBox(
                    width: 160,
                    child: AppPrimaryButton(
                      onPressed: onCreate,
                      icon: Icons.add,
                      label: l10n.addNew,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (filtered.isEmpty)
              ConsoleEmptyState(
                icon: Icons.people_outline,
                text: search.isNotEmpty
                    ? l10n.nothingFound
                    : l10n.superAdminNoActiveOwners,
              )
            else
              ...filtered.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
                  child: OwnerCard(owner: o, onTap: () => onTap(o)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
