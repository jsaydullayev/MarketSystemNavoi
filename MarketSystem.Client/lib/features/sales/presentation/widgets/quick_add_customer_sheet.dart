import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/customer_service.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Minimal "create a customer right now" bottom sheet.
///
/// Used by the payment dialogs (PaymentDialog / ContinuePaymentSheet) when
/// the cashier wants to close a sale as debt but hasn't picked a customer
/// yet. Instead of forcing them to cancel the payment flow, back out to the
/// customer picker, and re-open payment, they create one inline.
///
/// On a successful create the sheet pops with the created customer Map
/// (`{id, fullName, phone}`). On cancel it pops with null.
///
/// This widget intentionally does NOT attach the customer to any sale —
/// that's the caller's job, because the "new sale" flow has no sale id yet
/// while the "continue sale" flow does. The caller decides what to do with
/// the returned Map.
class QuickAddCustomerSheet extends StatefulWidget {
  const QuickAddCustomerSheet({super.key});

  @override
  State<QuickAddCustomerSheet> createState() => _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState extends State<QuickAddCustomerSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Phone is the only required field — a customer has to be reachable to
    // chase a debt. Full name can be filled in later from the Customers tab.
    if (phone.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.fillIn),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final created = await CustomerService(authProvider: auth).createCustomer(
        phone: phone,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );

      // Normalise the response into a plain Map the payment dialogs expect.
      // createCustomer returns the decoded JSON body; defend against shapes.
      if (created is Map) {
        final result = <String, dynamic>{
          'id': created['id']?.toString() ?? '',
          'fullName': (created['fullName'] ??
                  _nameCtrl.text.trim())
              .toString(),
          'phone': (created['phone'] ?? phone).toString(),
        };
        if (result['id']!.toString().isEmpty) {
          throw Exception('Customer created without an id');
        }
        navigator.pop(result);
        return;
      }
      throw Exception('Unexpected createCustomer response');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      // Lift the sheet above the keyboard so the phone field stays visible.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2,
          AppSpacing.lg,
          AppSpacing.xl2,
          AppSpacing.xl3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    l10n.addNewCustomer,
                    style: AppTextStyles.titleMedium(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed:
                      _isCreating ? null : () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextInput(
              controller: _nameCtrl,
              label: l10n.fullName,
              hint: l10n.fullName,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextInput(
              controller: _phoneCtrl,
              label: l10n.phone,
              hint: '+998…',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.cancel,
                    onPressed:
                        _isCreating ? null : () => Navigator.pop(context, null),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    label: l10n.save,
                    isLoading: _isCreating,
                    onPressed: _isCreating ? null : _create,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [QuickAddCustomerSheet] as a modal bottom sheet and resolves to the
/// created customer Map (`{id, fullName, phone}`), or null if the cashier
/// cancelled. Caller is responsible for whatever attaches the customer to a
/// sale.
Future<Map<String, dynamic>?> showQuickAddCustomerSheet(
    BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const QuickAddCustomerSheet(),
  );
}
