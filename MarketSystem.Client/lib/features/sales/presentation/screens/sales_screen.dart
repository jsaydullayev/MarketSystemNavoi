import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/error_retry_view.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/file_helper.dart' as core_file_helper;
import '../../../../core/utils/pdf_print_helper.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/sales_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sale_entity.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/states/sales_state.dart';
import '../widgets/sales_screen_hero_summary.dart';
import '../widgets/sales_screen_list_states.dart';
import '../widgets/sales_screen_sale_item.dart';
import '../widgets/sales_screen_status_chips.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedStatus = 'all';
  bool _isExporting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSales();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<SalesBloc>().state;
      if (state is SalesLoaded && state.hasMore) {
        context.read<SalesBloc>().add(const LoadMoreSalesEvent());
      }
    }
  }

  void _loadSales() {
    context.read<SalesBloc>().add(const GetSalesEvent());
  }

  List<SaleEntity> _filterSales(List<SaleEntity> sales) {
    List<SaleEntity> filtered;

    if (_selectedStatus == 'all') {
      filtered = List.from(sales);
    } else {
      filtered = sales
          .where((s) => s.getStatusText().toLowerCase() == _selectedStatus)
          .toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final lang = Localizations.localeOf(context).languageCode;
      final salesService = SalesService(authProvider: authProvider);
      final bytes = await salesService.downloadSalesExcel(lang: lang);

      if (bytes != null && bytes.isNotEmpty) {
        final fileName = lang == 'ru' ? 'Prodazhi.xlsx' : 'Sotuvlar.xlsx';
        final success = await core_file_helper.FileHelper.saveAndOpenExcel(
          bytes,
          fileName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                kIsWeb && success
                    ? 'Excel fayli yuklanmoqda...'
                    : (success ? 'Excel saqlandi va ochildi' : 'Error'),
              ),
              backgroundColor: success ? AppColors.success : AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final lang = Localizations.localeOf(context).languageCode;
      final bytes = await salesService.downloadSalesPdf(lang: lang);

      if (bytes != null && bytes.isNotEmpty) {
        final success = await core_file_helper.FileHelper.saveAndOpenPdf(
          bytes,
          'Sotuvlar.pdf',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                kIsWeb && success
                    ? 'PDF fayli yuklanmoqda...'
                    : (success
                          ? 'PDF saqlandi va ochildi'
                          : 'PDF saqlashda xatolik'),
              ),
              backgroundColor: success ? AppColors.success : AppColors.danger,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF faylini yuklab olishda xatolik yuz berdi'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// Sotuvlar ro'yxatini (A4 landshaft PDF) OS print oynasi orqali pechatga
  /// beradi — mavjud `downloadSalesPdf` baytlari `printPdfBytes` ga uzatiladi.
  Future<void> _printSalesPdf() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final lang = Localizations.localeOf(context).languageCode;
      final bytes = await salesService.downloadSalesPdf(lang: lang);

      if (bytes != null && bytes.isNotEmpty) {
        await printPdfBytes(bytes, name: 'sotuvlar');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF faylini yuklab olishda xatolik yuz berdi'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: NetworkWrapper(
        onRetry: _loadSales,
        child: Scaffold(
          backgroundColor: context.colors.bg,
          appBar: CommonAppBar(
            title: l10n.sales,
            onRefresh: _loadSales,
            extraActions: _isExporting
                ? [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colors.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                : [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.file_download_outlined,
                        color: context.colors.text,
                      ),
                      tooltip: 'Export',
                      onSelected: (value) {
                        if (value == 'excel') {
                          _exportExcel();
                        } else if (value == 'pdf') {
                          _exportPdf();
                        } else if (value == 'print') {
                          _printSalesPdf();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.table_view,
                                size: 20,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(
                                'Excel export',
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 20,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(
                                'PDF export',
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(
                                Icons.print_outlined,
                                size: 20,
                                color: context.colors.brand,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(
                                l10n.printAction,
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: BlocBuilder<SalesBloc, SalesState>(
                builder: (context, state) {
                  if (state is SalesLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colors.brand,
                        ),
                      ),
                    );
                  }

                  if (state is SalesLoaded || state is SalesLoadingMore) {
                    final sales = state is SalesLoaded
                        ? state.sales
                        : (state as SalesLoadingMore).sales;
                    final hasMore =
                        state is SalesLoaded ? state.hasMore : false;
                    final isLoadingMore = state is SalesLoadingMore;
                    final filteredSales = _filterSales(sales);
                    return Column(
                      children: [
                        SalesHeroSummary(sales: sales, l10n: l10n),
                        SalesStatusChips(
                          sales: sales,
                          l10n: l10n,
                          selectedStatus: _selectedStatus,
                          onStatusSelected: (id) =>
                              setState(() => _selectedStatus = id),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            color: context.colors.brand,
                            onRefresh: () async => _loadSales(),
                            child: filteredSales.isEmpty
                                ? SalesEmptyState(l10n: l10n)
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xl,
                                    ),
                                    itemCount: filteredSales.length +
                                        (hasMore || isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == filteredSales.length) {
                                        return SalesLoadMoreIndicator(
                                          isLoading: isLoadingMore,
                                          onLoadMore: () => context
                                              .read<SalesBloc>()
                                              .add(
                                                const LoadMoreSalesEvent(),
                                              ),
                                        );
                                      }
                                      return SalesSaleItem(
                                        sale: filteredSales[index],
                                        l10n: l10n,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BlocProvider.value(
                                              value:
                                                  context.read<SalesBloc>(),
                                              child: SaleDetailScreen(
                                                saleId:
                                                    filteredSales[index].id,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    );
                  }
                  // D1 — explicit Error state branch. Previously the
                  // BlocBuilder fell through to SizedBox.shrink() leaving a
                  // blank screen after a load failure (the listener fired a
                  // one-shot snackbar then the body had nothing to render
                  // and no way to retry — RefreshIndicator only works when
                  // a list is on screen).
                  if (state is SalesError) {
                    return RefreshIndicator(
                      color: context.colors.brand,
                      onRefresh: () async => _loadSales(),
                      child: ErrorRetryView(
                        message: state.message,
                        onRetry: _loadSales,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SalesBloc>(),
                    child: const NewSaleScreen(),
                  ),
                ),
              );
              if (result == true && mounted) _loadSales();
            },
            backgroundColor: context.colors.brand,
            icon: Icon(
              Icons.add_shopping_cart_rounded,
              color: context.colors.onBrand,
            ),
            label: Text(
              l10n.newSale,
              style: AppTextStyles.labelLarge().copyWith(
                color: context.colors.onBrand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
