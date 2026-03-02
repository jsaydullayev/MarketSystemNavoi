import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
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
      final products =
          await ProductService(authProvider: authProvider).getAllProducts();
      if (mounted) setState(() => _products = products);
    } catch (_) {
      if (mounted) setState(() => _products = []);
    }
  }

  void _openAddSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];

    if (userRole != 'Admin' && userRole != 'Owner') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.onlyAdminOwnerCanAdd),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.noProductsAddFirst),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    AddZakupSheet.show(context, products: _products);
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bytes =
          await ZakupService(authProvider: authProvider).downloadZakupsExcel();

      if (bytes != null && bytes.isNotEmpty) {
        final path = await core_file_helper.FileHelper.saveAndOpenExcel(
            bytes, 'Xaridlar.xlsx');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                path != null ? '${l10n.fileSaved}: $path' : l10n.fileSaveError),
            backgroundColor: path != null ? Colors.green : Colors.red,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.errorLoadingData),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.errorOccurred}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'];
    final canAdd = userRole == 'Admin' || userRole == 'Owner';

    return BlocListener<ZakupBloc, ZakupState>(
      listener: (context, state) {
        if (state is ZakupCreated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.zakupSuccess),
            backgroundColor: Colors.green,
          ));
          context.read<ZakupBloc>().add(const GetZakupsEvent());
        } else if (state is ZakupError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.zakup,
          onRefresh: () =>
              context.read<ZakupBloc>().add(const GetZakupsEvent()),
          extraActions: [
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
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
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: zakups.length,
                  itemBuilder: (_, i) => ZakupCard(zakup: zakups[i]),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: canAdd
            ? FloatingActionButton.extended(
                onPressed: () => _openAddSheet(context),
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                elevation: 2,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  l10n.addPurchase,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Helper views ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPurchases,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
