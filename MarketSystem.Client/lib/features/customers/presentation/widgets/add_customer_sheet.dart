import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/customers/presentation/widgets/custom_text_field.dart';
import 'package:market_system_client/features/customers/presentation/widgets/phone_validator.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/events/customers_event.dart';
import 'debt_toggle.dart';

class AddCustomerSheet extends StatefulWidget {
  const AddCustomerSheet({super.key});

  @override
  State<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _commentController = TextEditingController();
  final _debtAmountController = TextEditingController();
  bool _hasDebt = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _commentController.dispose();
    _debtAmountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final initialDebt = _hasDebt
        ? double.tryParse(
            _debtAmountController.text.trim().replaceAll(',', '.'))
        : null;

    context.read<CustomersBloc>().add(
          CreateCustomerEvent(
            phone: _phoneController.text.trim(),
            fullName: _fullNameController.text.trim().isEmpty
                ? null
                : _fullNameController.text.trim(),
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
            initialDebt: initialDebt,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl3,
        top: AppSpacing.xl3,
        left: AppSpacing.xl2,
        right: AppSpacing.xl2,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.brand, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(l10n.addNewCustomer,
                      style: AppTextStyles.titleMedium()),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),
              CustomTextField(
                controller: _fullNameController,
                label: l10n.fullName,
                icon: Icons.person_rounded,
                helperText: "Mijoz uchun chiroyli ko'rinadigan nom",
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                controller: _phoneController,
                label: l10n.phoneNumber,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                helperText: 'SMS eslatma yuborish uchun kerak',
                validator: (value) =>
                    PhoneValidator.validate(value, l10n: l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                controller: _commentController,
                label: l10n.commentOptional,
                icon: Icons.comment_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.debtStatus.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DebtToggle(
                hasDebt: _hasDebt,
                onChanged: (value) => setState(() {
                  _hasDebt = value;
                  if (!value) _debtAmountController.clear();
                }),
              ),
              if (_hasDebt) ...[
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  controller: _debtAmountController,
                  label: l10n.debtAmountSom,
                  icon: Icons.monetization_on_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.debtAmountRequired;
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return l10n.debtAmountPositive;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.debtRecordWillBeCreated,
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.brandDark, size: 18),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        "Yangi mijozni qo'shgach, har sotuvda uni tanlash mumkin va qarz tarixi avtomatik yuritiladi.",
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.brandDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              AppPrimaryButton(
                label: l10n.add,
                onPressed: _submit,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: l10n.cancel,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
