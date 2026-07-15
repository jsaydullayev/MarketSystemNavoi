import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/supplier_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../design/widgets/app_text_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/supplier_entity.dart';

/// Add / edit a supplier. Returns `true` via [Navigator.pop] when a supplier
/// was saved so the caller can refresh its list.
class SupplierFormSheet extends StatefulWidget {
  final SupplierEntity? existing;

  const SupplierFormSheet({super.key, this.existing});

  static Future<bool?> show(BuildContext context, {SupplierEntity? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupplierFormSheet(existing: existing),
    );
  }

  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _address = TextEditingController(text: s?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack(l10n.supplierRequired, isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final service = SupplierService(authProvider: auth);
      if (_isEdit) {
        await service.updateSupplier(
          id: widget.existing!.id,
          name: name,
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        );
      } else {
        await service.createSupplier(
          name: name,
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl2),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2,
          AppSpacing.lg,
          AppSpacing.xl2,
          AppSpacing.xl3,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isEdit ? l10n.editSupplier : l10n.addSupplier,
                style: AppTextStyles.titleMedium(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextInput(
                label: l10n.supplierNameLabel,
                hint: l10n.supplierNameHint,
                controller: _name,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextInput(
                label: l10n.supplierPhoneLabel,
                hint: '+998',
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextInput(
                label: l10n.supplierAddressLabel,
                controller: _address,
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: l10n.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      label: _saving ? '...' : l10n.save,
                      icon: Icons.check_rounded,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
