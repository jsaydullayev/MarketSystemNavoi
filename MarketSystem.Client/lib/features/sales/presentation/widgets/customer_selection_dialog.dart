import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/customer_service.dart';
import 'package:market_system_client/data/services/sales_service.dart';

/// Customer-picker dialog used in the sale + draft-sale flows.
///
/// In addition to picking from the existing customer list, the dialog now
/// has an inline "add new customer" row at the top of the list: tapping it
/// flips the dialog into a mini form (name + phone) and creates the
/// customer via `CustomerService.createCustomer` without forcing the user
/// to back out of the sale flow. After a successful create the new customer
/// is auto-selected on the current sale.
class CustomerSelectionDialog extends StatefulWidget {
  final String saleId;
  final VoidCallback onCustomerSelected;

  const CustomerSelectionDialog({
    super.key,
    required this.saleId,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  /// When true, the dialog body switches from the customer list to the
  /// inline "new customer" form. We never navigate away.
  bool _isAddMode = false;

  /// Bumping this key forces the FutureBuilder below to re-fetch the
  /// customers list after a successful create.
  int _listVersion = 0;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isCreating = false;

  // The customer list future is created ONCE per [_listVersion] and cached.
  // Previously `future: getAllCustomers()` was built inline every `build()`, so
  // every unrelated rebuild (add-mode toggle, _isCreating flip) re-fetched the
  // whole customer list from the network — mid-sale, a latency-sensitive moment.
  Future<List<dynamic>>? _customersFuture;
  int _futureVersion = -1;

  Future<List<dynamic>> _customers(BuildContext context) {
    if (_customersFuture == null || _futureVersion != _listVersion) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _customersFuture = CustomerService(
        authProvider: authProvider,
      ).getAllCustomers();
      _futureVersion = _listVersion;
    }
    return _customersFuture!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  Future<void> _createCustomer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillIn),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _isCreating = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerService = CustomerService(authProvider: authProvider);
    final salesService = SalesService(authProvider: authProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Capture the navigator up-front so the post-await pop() doesn't read
    // `context` synchronously after the async gap.
    final navigator = Navigator.of(context);
    try {
      final created = await customerService.createCustomer(
        phone: phone,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      // Auto-select the newly created customer on the current sale so the
      // user doesn't have to scroll the list and tap again.
      final newId = created is Map ? created['id']?.toString() : null;
      if (newId != null && newId.isNotEmpty) {
        await salesService.updateSaleCustomer(
          saleId: widget.saleId,
          customerId: newId,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.customerAdded}: ${_nameCtrl.text.trim().isEmpty ? phone : _nameCtrl.text.trim()}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onCustomerSelected();
        if (mounted) navigator.pop();
        return;
      }
      // No id came back — refresh the list so the user can pick manually.
      setState(() {
        _isAddMode = false;
        _isCreating = false;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _listVersion++;
      });
    } catch (e) {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl2),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.xl3,
      ),
      child: _isAddMode
          ? _buildAddForm(context, l10n)
          : FutureBuilder(
              future: _customers(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: 400,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.brand,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.error, style: AppTextStyles.titleMedium()),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${snapshot.error}',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl2),
                        AppSecondaryButton(
                          label: l10n.closed,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }

                final customersData = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: context.colors.brandLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              Icons.person_search_rounded,
                              color: context.colors.brand,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Text(
                              l10n.selectCustomer,
                              style: AppTextStyles.titleMedium(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: context.colors.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // "Add new customer" tile at the top of the list. Opens the
                      // inline mini form instead of navigating to /customers — the
                      // sale-in-progress context is preserved.
                      _AddCustomerTile(
                        label: l10n.addNewCustomer,
                        onTap: () => setState(() => _isAddMode = true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: 400,
                        height: 320,
                        child: customersData.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 64,
                                      color: context.colors.textMuted,
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Text(
                                      l10n.noCustomersFound,
                                      style: AppTextStyles.bodyMedium()
                                          .copyWith(
                                            color: context.colors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: customersData.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final customer = customersData[index];
                                  final customerName =
                                      customer['fullName'] ?? l10n.unknown;
                                  final customerPhone = customer['phone'] ?? '';
                                  final customerId =
                                      customer['id']?.toString() ?? '';
                                  final debt =
                                      (customer['totalDebt'] ??
                                              customer['debt'] ??
                                              0)
                                          .toString();

                                  return Material(
                                    color: context.colors.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.lg,
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        try {
                                          final salesService = SalesService(
                                            authProvider: authProvider,
                                          );
                                          await salesService.updateSaleCustomer(
                                            saleId: widget.saleId,
                                            customerId: customerId,
                                          );
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${l10n.customerAdded}: $customerName',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                          widget.onCustomerSelected();
                                        } catch (e) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${l10n.error}: $e',
                                              ),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.lg,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.colors.bg,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                          border: Border.all(
                                            color: context.colors.borderSoft,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: context.colors.inputFill,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                _initials(customerName),
                                                style:
                                                    AppTextStyles.labelLarge()
                                                        .copyWith(
                                                          color: context
                                                              .colors
                                                              .textSecondary,
                                                        ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.lg,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    customerName,
                                                    style:
                                                        AppTextStyles.bodyLarge()
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                  ),
                                                  if (customerPhone
                                                      .toString()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(
                                                      height: AppSpacing.xs,
                                                    ),
                                                    Text(
                                                      customerPhone,
                                                      style:
                                                          AppTextStyles.bodySmall(),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (debt != '0' && debt.isNotEmpty)
                                              Text(
                                                debt,
                                                style:
                                                    AppTextStyles.labelLarge()
                                                        .copyWith(
                                                          color: context
                                                              .colors
                                                              .brand,
                                                        ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: AppDangerButton(
                              label: l10n.removeCustomer,
                              onPressed: () async {
                                Navigator.pop(context);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final salesService = SalesService(
                                    authProvider: authProvider,
                                  );
                                  await salesService.updateSaleCustomer(
                                    saleId: widget.saleId,
                                    customerId: null,
                                  );
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.customerRemoved),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  widget.onCustomerSelected();
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('${l10n.error}: $e'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: AppSecondaryButton(
                              label: l10n.cancel,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Inline mini-form for creating a new customer. Phone is required; full
  /// name is optional (the user can fill it later from the Customers tab).
  /// On success the new customer is auto-selected on the current sale and
  /// the dialog closes — no extra round-trip through the customers screen.
  Widget _buildAddForm(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: context.colors.brand,
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
                icon: Icon(Icons.close, color: context.colors.textSecondary),
                onPressed: () => setState(() => _isAddMode = false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.cancel,
                  onPressed: _isCreating
                      ? null
                      : () => setState(() => _isAddMode = false),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  label: l10n.save,
                  isLoading: _isCreating,
                  onPressed: _isCreating
                      ? null
                      : () => _createCustomer(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "+ Yangi mijoz qo'shish" tile rendered above the customer list. Tapping
/// flips the parent into the inline create-form.
class _AddCustomerTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddCustomerTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.colors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: context.colors.brand.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
