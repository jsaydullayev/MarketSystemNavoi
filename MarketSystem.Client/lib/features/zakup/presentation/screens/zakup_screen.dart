// lib/features/zakup/presentation/screens/zakup_screen.dart
//
// Goods-receipt (priyomka) history. Each row is a supplier delivery of one or
// more products; tap to expand line items, pay the supplier, or delete.

import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/zakup_service.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import '../../domain/entities/zakup_receipt_entity.dart';
import '../widgets/add_zakup_receipt_sheet.dart';
import '../widgets/zakup_receipt_card.dart';

class ZakupScreen extends StatefulWidget {
  const ZakupScreen({super.key});

  @override
  State<ZakupScreen> createState() => _ZakupScreenState();
}

class _ZakupScreenState extends State<ZakupScreen> {
  List<dynamic> _products = [];
  List<ZakupReceiptEntity> _receipts = [];
  bool _loading = true;
  String? _error;
  bool _isExporting = false;

  ZakupService get _service => ZakupService(
    authProvider: Provider.of<AuthProvider>(context, listen: false),
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadReceipts();
  }

  Future<void> _loadProducts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final products = await ProductService(
        authProvider: authProvider,
      ).getAllProducts();
      if (mounted) setState(() => _products = products);
    } catch (e, st) {
      debugPrint('ZakupScreen._loadProducts error: $e\n$st');
      if (mounted) setState(() => _products = []);
    }
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _service.getAllReceipts();
      final list = raw
          .map((e) => ZakupReceiptEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _receipts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openAddSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.can(Permissions.zakupCreate)) {
      _showSnack(l10n.onlyAdminOwnerCanAdd, isError: true);
      return;
    }
    if (_products.isEmpty) {
      _showSnack(l10n.noProductsAddFirst, warning: true);
      return;
    }
    final created = await AddZakupReceiptSheet.show(context, products: _products);
    if (created == true) {
      if (!mounted) return;
      _showSnack(l10n.receiptCreated);
      _loadReceipts();
      _loadProducts(); // stock changed
    }
  }

  Future<void> _deleteReceipt(ZakupReceiptEntity r) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(l10n.confirmDelete, style: AppTextStyles.titleMedium()),
        content: Text(
          l10n.deleteReceiptConfirm,
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
    if (ok != true) return;
    try {
      await _service.deleteReceipt(r.id);
      if (!mounted) return;
      _showSnack(l10n.deleteSuccess);
      _loadReceipts();
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      _showSnack('${l10n.errorOccurred}: $e', isError: true);
    }
  }

  Future<void> _payReceipt(ZakupReceiptEntity r) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: NumberFormatter.format(r.outstandingAmount).replaceAll(' ', ''),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(l10n.payToSupplier, style: AppTextStyles.titleMedium()),
        content: AppTextInput(
          label: l10n.paymentAmountLabel,
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [NoLeadingZeroFormatter()],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.brand,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = double.tryParse(
                ctrl.text.trim().replaceAll(',', '.'),
              );
              Navigator.pop(ctx, v);
            },
            child: Text(l10n.payToSupplier),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      await _service.registerReceiptPayment(r.id, amount);
      if (!mounted) return;
      _showSnack(l10n.paymentRegistered);
      _loadReceipts();
    } catch (e) {
      if (!mounted) return;
      _showSnack('${l10n.errorOccurred}: $e', isError: true);
    }
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final bytes = await _service.downloadZakupsExcel();
      if (bytes != null && bytes.isNotEmpty) {
        final ok = await core_file_helper.FileHelper.saveAndOpenExcel(
          bytes,
          'Xaridlar.xlsx',
        );
        if (mounted) {
          _showSnack(ok ? l10n.fileSaved : l10n.fileSaveError, isError: !ok);
        }
      } else if (mounted) {
        _showSnack(l10n.errorLoadingData, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('${l10n.errorOccurred}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnack(String message, {bool isError = false, bool warning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.danger
            : warning
            ? AppColors.warning
            : AppColors.success,
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
    final authProvider = Provider.of<AuthProvider>(context);
    final canAdd = authProvider.can(Permissions.zakupCreate);
    final canDelete = authProvider.can(Permissions.zakupDelete);
    final canViewCost = authProvider.can(Permissions.dataCostPrice);
    final canPay = authProvider.can(Permissions.zakupCreate);

    return NetworkWrapper(
      onRetry: () {
        _loadProducts();
        _loadReceipts();
      },
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(
          title: l10n.zakup,
          onRefresh: _loadReceipts,
          extraActions: [
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: l10n.exportExcel,
                    onPressed: _exportExcel,
                  ),
          ],
        ),
        body: _buildBody(l10n, canDelete, canViewCost, canPay),
        floatingActionButton: canAdd
            ? FloatingActionButton.extended(
                onPressed: _openAddSheet,
                backgroundColor: context.colors.brand,
                foregroundColor: context.colors.onBrand,
                elevation: 2,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  l10n.newReceipt,
                  style: AppTextStyles.labelLarge().copyWith(
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    bool canDelete,
    bool canViewCost,
    bool canPay,
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
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(label: l10n.retry, onPressed: _loadReceipts),
            ],
          ),
        ),
      );
    }
    if (_receipts.isEmpty) {
      return _EmptyView(l10n: l10n);
    }

    return RefreshIndicator(
      onRefresh: _loadReceipts,
      color: context.colors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          100,
        ),
        itemCount: _receipts.length,
        itemBuilder: (_, i) {
          final r = _receipts[i];
          return ZakupReceiptCard(
            receipt: r,
            canViewCost: canViewCost,
            onDelete: canDelete ? () => _deleteReceipt(r) : null,
            onPay: canPay ? () => _payReceipt(r) : null,
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl3),
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: context.colors.brand,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.noReceipts,
            style: AppTextStyles.bodyLarge().copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
