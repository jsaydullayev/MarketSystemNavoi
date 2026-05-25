// Editable Owner+Market fields — migrated to the new design system.
// Username/password are intentionally NOT editable here — both invalidate
// JWTs and audit links and live behind separate operations.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../design/widgets/app_text_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/superadmin_service.dart';
import '../../domain/models/owner_detail.dart';

class EditOwnerDialog extends StatefulWidget {
  const EditOwnerDialog({super.key, required this.detail});
  final OwnerDetail detail;

  @override
  State<EditOwnerDialog> createState() => _EditOwnerDialogState();
}

class _EditOwnerDialogState extends State<EditOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _marketName;
  late final TextEditingController _subdomain;
  late final TextEditingController _description;
  late bool _ownerActive;
  late bool _marketActive;
  String _language = 'uz';
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _fullName = TextEditingController(text: d.fullName);
    _phone = TextEditingController(text: d.phone ?? '');
    _marketName = TextEditingController(text: d.market?.name ?? '');
    _subdomain = TextEditingController(text: d.market?.subdomain ?? '');
    _description = TextEditingController(text: d.market?.description ?? '');
    _ownerActive = d.isActive;
    _marketActive = d.market?.isActive ?? true;
    _language = d.language.startsWith('ru') ? 'ru' : 'uz';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _marketName.dispose();
    _subdomain.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.updateOwner(
      userId: widget.detail.userId,
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      language: _language,
      marketName: _marketName.text.trim(),
      subdomain: _subdomain.text.trim().isEmpty
          ? null
          : _subdomain.text.trim().toLowerCase(),
      description: _description.text.trim(),
      ownerActive: _ownerActive,
      marketActive: _marketActive,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success && res.data != null) {
      Navigator.of(context).pop(res.data);
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = res.message ?? l10n.updateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.colors.brandLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: context.colors.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          l10n.updateInfoTitle,
                          style: AppTextStyles.titleMedium(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: context.colors.textSecondary,
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${widget.detail.fullName} · @${widget.detail.username}',
                    style: AppTextStyles.bodySmall(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_errorMessage case final msg?) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              msg,
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _SectionTitle(l10n.ownerSection),
                  const SizedBox(height: AppSpacing.md),
                  AppTextInput(
                    label: l10n.fullNameLabel,
                    controller: _fullName,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v ?? '').trim().length < 2
                        ? l10n.nameRequiredShort
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextInput(
                          label: l10n.phoneLabel,
                          controller: _phone,
                          prefixIcon: Icons.phone_outlined,
                          hint: l10n.phoneHintExample,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _languageDropdown()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SwitchTile(
                    title: l10n.ownerActive,
                    value: _ownerActive,
                    onChanged: (v) => setState(() => _ownerActive = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle(l10n.shopSection),
                  const SizedBox(height: AppSpacing.md),
                  AppTextInput(
                    label: l10n.shopName,
                    controller: _marketName,
                    prefixIcon: Icons.storefront_outlined,
                    validator: (v) =>
                        (v ?? '').trim().length < 3 ? l10n.minCharsShort : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextInput(
                    label: l10n.subdomainLabel,
                    controller: _subdomain,
                    prefixIcon: Icons.language_outlined,
                    hint: l10n.subdomainHintExample,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextInput(
                    label: l10n.descriptionLabel,
                    controller: _description,
                    prefixIcon: Icons.notes_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SwitchTile(
                    title: l10n.shopActive,
                    value: _marketActive,
                    onChanged: (v) => setState(() => _marketActive = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: l10n.cancel,
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: AppPrimaryButton(
                          label: l10n.save,
                          icon: Icons.save_outlined,
                          isLoading: _submitting,
                          onPressed: _submitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.languageUpper,
          style: AppTextStyles.caption().copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _language,
          style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: BorderSide(color: context.colors.brand, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'uz', child: Text("O'zbek")),
            DropdownMenuItem(value: 'ru', child: Text('Русский')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _language = v);
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.colors.brand,
          ),
        ],
      ),
    );
  }
}
