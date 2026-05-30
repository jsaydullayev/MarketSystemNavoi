import 'dart:typed_data';

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
import 'widgets/import_screen_done_widgets.dart';
import 'widgets/import_screen_idle_widgets.dart';
import 'widgets/import_screen_preview_widgets.dart';

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

  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    final Uint8List bytes;
    try {
      bytes = ProductImportService.generateTemplate(lang: lang);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.importErrorGenerate}: $e')),
        );
      }
      return;
    }

    if (bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importErrorGenerate)),
        );
      }
      return;
    }

    final ok = await fh.FileHelper.saveAndOpenExcel(
      bytes,
      l10n.importTemplateFileName,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.importTemplateDownloaded),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.importErrorSaveFile),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
          InfoCard(
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
          ColumnGuide(l10n),

          const SizedBox(height: AppSpacing.xl2),

          // Xato xabari
          if (_error != null) ...[
            ErrorBanner(_error!),
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
        SummaryBanner(preview: p),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: ErrorBanner(_error!),
          ),

        // Qatorlar ro'yxati
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            itemCount: p.rows.length,
            itemBuilder: (_, i) => RowCard(row: p.rows[i]),
          ),
        ),

        // Alt tugmalar
        PreviewActions(
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
            StatRow(l10n.importSaved,
                l10n.importCountProducts(r.importedCount), AppColors.success),
            if (r.newCategoriesCreated > 0)
              StatRow(l10n.importNewCategory,
                  l10n.importCountItems(r.newCategoriesCreated), AppColors.info),
            if (r.skippedCount > 0)
              StatRow(l10n.importSkipped,
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
