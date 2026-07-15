import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../data/services/supplier_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_card.dart';
import '../../../../design/widgets/app_text_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/supplier_entity.dart';
import '../widgets/supplier_form_sheet.dart';

/// Yetkazib beruvchilar (suppliers) directory — list + add/edit/delete.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  List<SupplierEntity> _all = [];
  List<SupplierEntity> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final raw = await SupplierService(authProvider: auth).getAllSuppliers();
      final list = raw
          .map((e) => SupplierEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all
                .where(
                  (s) =>
                      s.name.toLowerCase().contains(q) ||
                      (s.phone ?? '').toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _openForm({SupplierEntity? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await SupplierFormSheet.show(context, existing: existing);
    if (!mounted) return;
    if (saved == true) {
      _snack(l10n.supplierSaved);
      _load();
    }
  }

  Future<void> _delete(SupplierEntity s) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await SupplierService(authProvider: auth).deleteSupplier(s.id);
      if (!mounted) return;
      _snack(l10n.deleteSuccess);
      _load();
    } catch (e) {
      if (!mounted) return;
      _snack('${l10n.errorOccurred}: $e', isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context);
    final canManage = auth.can(Permissions.suppliersManage);
    final canDelete = auth.can(Permissions.suppliersDelete);
    final canViewDebt = auth.can(Permissions.dataCostPrice);

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: CommonAppBar(title: l10n.suppliersTitle, onRefresh: _load),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: context.colors.brand,
              foregroundColor: context.colors.onBrand,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                l10n.addSupplier,
                style: AppTextStyles.labelLarge().copyWith(color: Colors.white),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: AppTextInput(
              hint: l10n.searchSupplier,
              controller: _searchCtrl,
              prefixIcon: Icons.search_rounded,
            ),
          ),
          Expanded(child: _buildBody(l10n, canManage, canDelete, canViewDebt)),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    bool canManage,
    bool canDelete,
    bool canViewDebt,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColors.danger,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.noSuppliers,
          style: AppTextStyles.bodyLarge().copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: context.colors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          100,
        ),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _SupplierRow(
          supplier: _filtered[i],
          canViewDebt: canViewDebt,
          onTap: canManage ? () => _openForm(existing: _filtered[i]) : null,
          onDelete: canDelete ? () => _delete(_filtered[i]) : null,
        ),
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  final SupplierEntity supplier;
  final bool canViewDebt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _SupplierRow({
    required this.supplier,
    required this.canViewDebt,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDebt = canViewDebt && supplier.outstandingDebt > 0;

    Widget inner = AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.lg - 1),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: context.colors.brand,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: AppTextStyles.bodyLarge().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      supplier.phone!,
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDebt)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.supplierDebtLabel,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.danger,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      NumberFormatter.format(supplier.outstandingDebt),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
    );

    if (onTap != null) {
      inner = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: inner,
      );
    }

    final card = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      child: inner,
    );

    if (onDelete == null) return card;
    return Dismissible(
      key: ValueKey('supplier_${supplier.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md + 2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(supplier.name, style: AppTextStyles.titleMedium()),
            content: Text(
              l10n.deleteSupplierConfirm,
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.no),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (ok == true) onDelete!();
        return false;
      },
      child: card,
    );
  }
}
