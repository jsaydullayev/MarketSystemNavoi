import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_theme_colors.dart';
import '../../../../../design/tokens/app_tokens.dart';
import '../../../../../design/tokens/app_typography.dart';
import '../../../../../design/widgets/app_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/import_models.dart';

class SummaryBanner extends StatelessWidget {
  final ImportPreviewResult preview;
  const SummaryBanner({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg,
    ),
    color: context.colors.surface,
    child: Row(
      children: [
        Expanded(
          child: Text(
            l10n.importRowsAnalyzed(preview.rows.length),
            style: AppTextStyles.bodyMedium()
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _Badge(preview.validCount, AppColors.success, Icons.check_circle_rounded),
        const SizedBox(width: AppSpacing.md),
        _Badge(preview.warningCount, AppColors.warning, Icons.warning_amber_rounded),
        const SizedBox(width: AppSpacing.md),
        _Badge(preview.errorCount, AppColors.danger, Icons.cancel_rounded),
      ],
    ),
  );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;
  const _Badge(this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text('$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          )),
    ],
  );
}

class RowCard extends StatelessWidget {
  final ImportRowResult row;
  const RowCard({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isError = row.status == ImportRowStatus.error;
    final isWarn = row.status == ImportRowStatus.warning;
    final statusColor = isError
        ? AppColors.danger
        : isWarn
            ? AppColors.warning
            : AppColors.success;
    final statusIcon = isError
        ? Icons.cancel_rounded
        : isWarn
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Qator raqami
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text(
              '${row.rowNumber}',
              style: AppTextStyles.caption().copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Asosiy kontent
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tovar nomi + narx
                Row(children: [
                  Expanded(
                    child: Text(
                      row.resolvedName ?? row.inputName ?? '—',
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w600,
                        color: isError
                            ? context.colors.textMuted
                            : context.colors.text,
                      ),
                    ),
                  ),
                  if (row.resolvedSalePrice != null)
                    Text(
                      '${_fmt(row.resolvedSalePrice!)} so\'m',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                ]),

                // Kategoriya / birlik
                if (row.resolvedCategoryName != null ||
                    row.resolvedUnitName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    if (row.resolvedCategoryName != null) ...[
                      Icon(Icons.folder_outlined,
                          size: 12, color: context.colors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        row.isNewCategory
                            ? '${row.resolvedCategoryName} (${l10n.importNewCategory.toLowerCase()})'
                            : row.resolvedCategoryName!,
                        style: AppTextStyles.caption().copyWith(
                          color: row.isNewCategory
                              ? AppColors.info
                              : context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Text(
                      row.resolvedUnitName,
                      style: AppTextStyles.caption().copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  ]),
                ],

                // Xatolar va ogohlantirishlar
                if (row.errors.isNotEmpty || row.warnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ...row.errors.map((e) => _MessageLine(
                      e, AppColors.danger, Icons.error_outline_rounded)),
                  ...row.warnings.map((w) => _MessageLine(
                      w, AppColors.warning, Icons.info_outline_rounded)),
                ],
              ],
            ),
          ),

          // Status icon
          const SizedBox(width: AppSpacing.md),
          Icon(statusIcon, color: statusColor, size: 18),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(0);
  }
}

class _MessageLine extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _MessageLine(this.text, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption().copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class PreviewActions extends StatelessWidget {
  final ImportPreviewResult preview;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  const PreviewActions({
    super.key,
    required this.preview,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final importable = preview.validCount + preview.warningCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSecondaryButton(
              label: l10n.back,
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            flex: 2,
            child: AppPrimaryButton(
              label: importable > 0
                  ? l10n.importConfirmButton(importable)
                  : l10n.importAllErrors,
              onPressed: importable > 0 ? onConfirm : null,
            ),
          ),
        ],
      ),
    );
  }
}
