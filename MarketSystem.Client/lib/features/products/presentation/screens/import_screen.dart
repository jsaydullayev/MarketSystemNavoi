import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/file_helper.dart' as fh;
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/import_models.dart';
import '../../data/services/product_import_service.dart';

// ── Bosqichlar ─────────────────────────────────────────────────────────────
enum _Phase { idle, parsing, previewing, confirming, done }

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  _Phase _phase = _Phase.idle;
  String? _error;
  List<ImportProductRow>? _parsedRows;
  ImportPreviewResult? _preview;
  ImportResult? _result;
  late final ProductImportService _service;

  @override
  void initState() {
    super.initState();
    _service = ProductImportService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
  }

  // ── Harakatlar ─────────────────────────────────────────────────────────

  Future<void> _pickAndPreview() async {
    setState(() {
      _phase = _Phase.parsing;
      _error = null;
    });

    final rows = await _service.pickAndParseExcel();
    if (rows == null) {
      // Foydalanuvchi bekor qildi
      setState(() => _phase = _Phase.idle);
      return;
    }
    if (rows.isEmpty) {
      setState(() {
        _phase = _Phase.idle;
        _error = AppLocalizations.of(context)!.importFileEmpty;
      });
      return;
    }

    setState(() => _phase = _Phase.parsing);
    try {
      final preview = await _service.preview(rows);
      setState(() {
        _parsedRows = rows;
        _preview = preview;
        _phase = _Phase.previewing;
      });
    } catch (e) {
      setState(() {
        _phase = _Phase.idle;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirm() async {
    final rows = _parsedRows;
    if (rows == null) return;
    setState(() => _phase = _Phase.confirming);
    try {
      final result = await _service.confirm(
        ImportConfirmRequest(rows: rows),
      );
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    } catch (e) {
      setState(() {
        _phase = _Phase.previewing;
        _error = e.toString();
      });
    }
  }

  void _downloadTemplate() {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final bytes = ProductImportService.generateTemplate(lang: lang);
    fh.FileHelper.saveAndOpenExcel(bytes, l10n.importTemplateFileName);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: switch (_phase) {
              _Phase.idle || _Phase.parsing => _buildIdle(context, l10n),
              _Phase.previewing => _buildPreview(context, l10n),
              _Phase.confirming => _buildLoading(context, l10n.importSavingLabel),
              _Phase.done => _buildDone(context, l10n),
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: context.colors.surface,
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.importExcel,
        style: AppTextStyles.titleMedium().copyWith(
          color: context.colors.text,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: context.colors.text),
        onPressed: () => Navigator.maybePop(context, _phase == _Phase.done),
      ),
    );
  }

  // ── Idle ekrani ────────────────────────────────────────────────────────

  Widget _buildIdle(BuildContext context, AppLocalizations l10n) {
    final isLoading = _phase == _Phase.parsing;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Shablon yuklab olish kartasi
          _InfoCard(
            icon: Icons.table_chart_outlined,
            title: l10n.importDownloadTemplateFirst,
            subtitle: l10n.importFillInFormat,
            action: TextButton.icon(
              onPressed: isLoading ? null : _downloadTemplate,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.importDownloadTemplate),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Ustunlar tartibi
          _ColumnGuide(l10n),

          const SizedBox(height: AppSpacing.xl2),

          // Xato xabari
          if (_error != null) ...[
            _ErrorBanner(_error!),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Fayl tanlash tugmasi
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : AppPrimaryButton(
                  label: l10n.importSelectFile,
                  icon: Icons.upload_file_rounded,
                  onPressed: _pickAndPreview,
                ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ── Preview ekrani ─────────────────────────────────────────────────────

  Widget _buildPreview(BuildContext context, AppLocalizations l10n) {
    final p = _preview!;
    return Column(
      children: [
        // Xulosa banner
        _SummaryBanner(preview: p),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: _ErrorBanner(_error!),
          ),

        // Qatorlar ro'yxati
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            itemCount: p.rows.length,
            itemBuilder: (_, i) => _RowCard(row: p.rows[i]),
          ),
        ),

        // Alt tugmalar
        _PreviewActions(
          preview: p,
          onBack: () => setState(() {
            _phase = _Phase.idle;
            _error = null;
          }),
          onConfirm: _confirm,
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context, String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.xl),
        Text(msg, style: AppTextStyles.bodyMedium()),
      ],
    ),
  );

  // ── Done ekrani ────────────────────────────────────────────────────────

  Widget _buildDone(BuildContext context, AppLocalizations l10n) {
    final r = _result!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.importSuccess,
              style: AppTextStyles.titleMedium(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _StatRow(l10n.importSaved,
                l10n.importCountProducts(r.importedCount), AppColors.success),
            if (r.newCategoriesCreated > 0)
              _StatRow(l10n.importNewCategory,
                  l10n.importCountItems(r.newCategoriesCreated), AppColors.info),
            if (r.skippedCount > 0)
              _StatRow(l10n.importSkipped,
                  l10n.importCountItems(r.skippedCount), AppColors.warning),
            const SizedBox(height: AppSpacing.xl2),
            AppPrimaryButton(
              label: l10n.importClose,
              onPressed: () => Navigator.maybePop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Yordamchi widget'lar ───────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.colors.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.brand, size: 22),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium().copyWith(
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodySmall().copyWith(
                color: context.colors.textSecondary,
              )),
            ],
          ),
        ),
        action,
      ],
    ),
  );
}

class _ColumnGuide extends StatelessWidget {
  const _ColumnGuide(this.l10n);
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cols = [
      ('A', l10n.productName, true),
      ('B', l10n.salePrice, true),
      ('C', l10n.minPrice, false),
      ('D', l10n.category, false),
      ('E', l10n.importUnitHint, false),
      ('F', l10n.minThreshold, false),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importColumnGuide,
            style: AppTextStyles.bodyMedium()
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          ...cols.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(c.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    )),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(c.$2,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.text,
                  )),
              if (c.$3) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.importRequired,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ]),
          )),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final ImportPreviewResult preview;
  const _SummaryBanner({required this.preview});

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

class _RowCard extends StatelessWidget {
  final ImportRowResult row;
  const _RowCard({required this.row});

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

class _PreviewActions extends StatelessWidget {
  final ImportPreviewResult preview;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  const _PreviewActions({
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.danger, size: 18),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(message,
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.danger)),
        ),
      ],
    ),
  );
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textSecondary,
            )),
        Text(value,
            style: AppTextStyles.bodyMedium().copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            )),
      ],
    ),
  );
}
