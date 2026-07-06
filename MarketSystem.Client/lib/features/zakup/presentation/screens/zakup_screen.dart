// lib/features/zakup/presentation/screens/zakup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/zakup_service.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import '../bloc/zakup_bloc.dart';
import '../bloc/events/zakup_event.dart';
import '../bloc/states/zakup_state.dart';
import '../widgets/zakup_card.dart';
import '../widgets/add_zakup_sheet.dart';

class ZakupScreen extends StatefulWidget {
  const ZakupScreen({super.key});

  @override
  State<ZakupScreen> createState() => _ZakupScreenState();
}

class _ZakupScreenState extends State<ZakupScreen> {
  List<dynamic> _products = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    context.read<ZakupBloc>().add(const GetZakupsEvent());
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

  void _openAddSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];

    if (userRole != 'Admin' && userRole != 'Owner') {
      _showSnack(l10n.onlyAdminOwnerCanAdd, isError: true);
      return;
    }

    if (_products.isEmpty) {
      _showSnack(l10n.noProductsAddFirst, warning: true);
      return;
    }

    AddZakupSheet.show(context, products: _products);
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bytes = await ZakupService(
        authProvider: authProvider,
      ).downloadZakupsExcel();

      if (bytes != null && bytes.isNotEmpty) {
        final ok = await core_file_helper.FileHelper.saveAndOpenExcel(
          bytes,
          'Xaridlar.xlsx',
        );
        if (mounted) {
          _showSnack(ok ? l10n.fileSaved : l10n.fileSaveError, isError: !ok);
        }
      } else {
        if (mounted) {
          _showSnack(l10n.errorLoadingData, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('${l10n.errorOccurred}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteZakup(Map<String, dynamic> zakup) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ZakupService(
        authProvider: authProvider,
      ).deleteZakup(zakup['id'].toString());
      if (!mounted) return;
      _showSnack(l10n.deleteSuccess);
      context.read<ZakupBloc>().add(const GetZakupsEvent());
    } catch (e) {
      if (!mounted) return;
      _showSnack('${l10n.errorOccurred}: $e', isError: true);
    }
  }

  void _showSnack(
    String message, {
    bool isError = false,
    bool warning = false,
  }) {
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
    final userRole = authProvider.user?['role'];
    final canAdd = userRole == 'Admin' || userRole == 'Owner';
    final canDelete = authProvider.can(Permissions.zakupDelete);

    return BlocListener<ZakupBloc, ZakupState>(
      listener: (context, state) {
        if (state is ZakupCreated) {
          _showSnack(l10n.zakupSuccess);
          context.read<ZakupBloc>().add(const GetZakupsEvent());
        } else if (state is ZakupError) {
          _showSnack(state.message, isError: true);
        }
      },
      child: NetworkWrapper(
        onRetry: () {
          _loadProducts();
          context.read<ZakupBloc>().add(const GetZakupsEvent());
        },
        child: Scaffold(
          backgroundColor: context.colors.bg,
          appBar: CommonAppBar(
            title: l10n.zakup,
            onRefresh: () =>
                context.read<ZakupBloc>().add(const GetZakupsEvent()),
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
          body: BlocBuilder<ZakupBloc, ZakupState>(
            builder: (context, state) {
              if (state is ZakupLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ZakupError) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<ZakupBloc>().add(const GetZakupsEvent()),
                );
              }

              if (state is ZakupLoaded) {
                final zakups = state.zakups.map((z) => z.toJson()).toList();

                if (zakups.isEmpty) {
                  return _EmptyView(l10n: l10n);
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<ZakupBloc>().add(const GetZakupsEvent()),
                  color: context.colors.brand,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      100,
                    ),
                    itemCount: zakups.length,
                    itemBuilder: (_, i) => ZakupCard(
                      zakup: zakups[i],
                      onDelete: canDelete
                          ? () => _deleteZakup(zakups[i])
                          : null,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          floatingActionButton: canAdd
              ? FloatingActionButton.extended(
                  onPressed: () => _openAddSheet(context),
                  backgroundColor: context.colors.brand,
                  foregroundColor: context.colors.onBrand,
                  elevation: 2,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    l10n.addPurchase,
                    style: AppTextStyles.labelLarge().copyWith(
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
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
            l10n.noPurchases,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColors.danger,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(label: l10n.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
