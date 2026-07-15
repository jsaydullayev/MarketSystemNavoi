import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/supplier_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../suppliers/domain/entities/supplier_entity.dart';
import '../../../suppliers/presentation/widgets/supplier_form_sheet.dart';

/// Result of the supplier picker. [clearsSelection] means the user explicitly
/// chose "no supplier"; [supplier] carries the chosen one otherwise.
class SupplierPickResult {
  final bool clearsSelection;
  final SupplierEntity? supplier;
  const SupplierPickResult.cleared() : clearsSelection = true, supplier = null;
  const SupplierPickResult.chosen(this.supplier) : clearsSelection = false;
}

/// Bottom-sheet supplier picker used by the goods-receipt flow. Loads the
/// supplier directory, lets the user search, pick "none", or add a new supplier
/// inline. Returns null when dismissed without a choice.
class ZakupSupplierPicker extends StatefulWidget {
  final SupplierEntity? selected;
  const ZakupSupplierPicker({super.key, this.selected});

  static Future<SupplierPickResult?> show(
    BuildContext context, {
    SupplierEntity? selected,
  }) {
    return showModalBottomSheet<SupplierPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZakupSupplierPicker(selected: selected),
    );
  }

  @override
  State<ZakupSupplierPicker> createState() => _ZakupSupplierPickerState();
}

class _ZakupSupplierPickerState extends State<ZakupSupplierPicker> {
  final _searchCtrl = TextEditingController();
  List<SupplierEntity> _all = [];
  List<SupplierEntity> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final raw = await SupplierService(authProvider: auth).getAllSuppliers();
      if (!mounted) return;
      setState(() {
        _all = raw
            .map((e) => SupplierEntity.fromJson(e as Map<String, dynamic>))
            .toList();
        _filtered = _all;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = [];
        _filtered = [];
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _addNew() async {
    final saved = await SupplierFormSheet.show(context);
    if (!mounted) return;
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canManage = auth.can(Permissions.suppliersManage);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xs,
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl2,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.supplierLabel,
                    style: AppTextStyles.titleMedium(),
                  ),
                ),
                if (canManage)
                  TextButton.icon(
                    onPressed: _addNew,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addSupplier),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl2,
              0,
              AppSpacing.xl2,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.searchSupplier,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: context.colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // "No supplier" option
          ListTile(
            leading: Icon(
              Icons.block_rounded,
              color: context.colors.textMuted,
            ),
            title: Text(l10n.noSupplierSelected),
            trailing: widget.selected == null
                ? Icon(Icons.check_rounded, color: context.colors.brand)
                : null,
            onTap: () =>
                Navigator.pop(context, const SupplierPickResult.cleared()),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.noSuppliers,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final s = _filtered[i];
                      final isSel = s.id == widget.selected?.id;
                      return ListTile(
                        leading: Icon(
                          Icons.local_shipping_rounded,
                          color: context.colors.brand,
                        ),
                        title: Text(s.name),
                        subtitle: (s.phone != null && s.phone!.isNotEmpty)
                            ? Text(s.phone!)
                            : null,
                        trailing: isSel
                            ? Icon(
                                Icons.check_rounded,
                                color: context.colors.brand,
                              )
                            : null,
                        onTap: () => Navigator.pop(
                          context,
                          SupplierPickResult.chosen(s),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
