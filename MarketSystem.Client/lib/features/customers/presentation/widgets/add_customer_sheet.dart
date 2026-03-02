import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    final initialDebt =
        _hasDebt ? double.tryParse(_debtAmountController.text.trim()) : null;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_rounded,
                        color: primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.addNewCustomer,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _phoneController,
                label: l10n.phoneNumber,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    PhoneValidator.validate(value, l10n: l10n),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _fullNameController,
                label: l10n.fullNameOptional,
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _commentController,
                label: l10n.commentOptional,
                icon: Icons.comment_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              Text(
                l10n.debtStatus,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              DebtToggle(
                hasDebt: _hasDebt,
                onChanged: (value) => setState(() {
                  _hasDebt = value;
                  if (!value) _debtAmountController.clear();
                }),
              ),

              if (_hasDebt) ...[
                const SizedBox(height: 14),
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.debtRecordWillBeCreated,
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.add,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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
