import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/auth/permissions.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/core/utils/pdf_print_helper.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/sales/presentation/screens/continue_sale_screen.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/states/sales_state.dart';
import '../widgets/return_bottom_sheet.dart';
import '../widgets/sale_action_tiles.dart';
import '../widgets/sale_meta_card.dart';
import '../widgets/sale_receipt_card.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late final SalesService _salesService;

  // Re-entrancy guard for the print action — a double-tap on the print tile
  // must not stack two spinners or fire two print jobs.
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _salesService = SalesService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _loadSaleDetails();
  }

  void _loadSaleDetails() {
    context.read<SalesBloc>().add(GetSaleDetailEvent(widget.saleId));
  }

  Future<void> _downloadPdf(Map<String, dynamic> sale) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final lang = Localizations.localeOf(context).languageCode;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
        ),
      ),
    );

    try {
      final pdfData = await _salesService.downloadInvoice(
        widget.saleId,
        lang: lang,
      );

      if (pdfData == null || pdfData.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorOccurred),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final pdfBytes = Uint8List.fromList(pdfData);

      final createdAt = sale['createdAt'] != null
          ? (sale['createdAt'] is DateTime
                ? sale['createdAt'] as DateTime
                : DateTime.parse(sale['createdAt'].toString()))
          : DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy').format(createdAt);
      final fileName = 'faktura_${widget.saleId}_$dateStr.pdf';

      // Loading spinner'ni yopamiz, so'ng CHINAKAM print oynasini ochamiz.
      if (mounted) Navigator.pop(context);

      // "Chop etish" — barcha platformalarda tizim/brauzer PRINT oynasi
      // ochiladi (u yerdan printerga chiqarish yoki PDF saqlash mumkin).
      // Ilgari web'da fayl shunchaki yuklab olinar, print oynasi ochilmasdi.
      // Ichki try — layoutPdf xatosi tashqi catch'ga tushib spinner'ni
      // ikkinchi marta pop qilib, ekranni yopib qo'ymasligi uchun.
      try {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: fileName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorOccurred}: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
      return;
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOccurred}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Download the print-friendly compact invoice and hand it to the OS print
  /// dialog (Windows kassa: every press opens the system print window).
  ///
  /// The spinner route is popped exactly once (in the download `finally`); the
  /// print hand-off runs only after the spinner is already gone, so a print
  /// failure (printer offline, job cancelled in the OS dialog) just shows a
  /// snackbar instead of accidentally popping the screen itself.
  Future<void> _printInvoice(Map<String, dynamic> sale) async {
    if (_isPrinting) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    if (!mounted) return;

    _isPrinting = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
        ),
      ),
    );

    // Phase 1 — download behind the modal spinner; close it exactly once.
    List<int>? pdfData;
    try {
      pdfData = await _salesService.downloadInvoice(
        widget.saleId,
        lang: lang,
        compact: true,
      );
    } catch (_) {
      pdfData = null;
    } finally {
      if (mounted) Navigator.pop(context); // close the progress spinner
    }

    if (!mounted) {
      _isPrinting = false;
      return;
    }

    if (pdfData == null || pdfData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorOccurred),
          backgroundColor: AppColors.danger,
        ),
      );
      _isPrinting = false;
      return;
    }

    // Phase 2 — OS print dialog. No spinner route is open here, so a failure
    // only surfaces a snackbar; it can never pop a real screen.
    try {
      await printPdfBytes(pdfData, name: 'faktura_${widget.saleId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOccurred}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      _isPrinting = false;
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
        } else if (state is SaleItemReturned) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.returnSuccess),
              backgroundColor: AppColors.success,
            ),
          );
          _loadSaleDetails();
        } else if (state is SaleDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saleDeleted),
              backgroundColor: AppColors.success,
            ),
          );
          // Refresh the list behind us and leave the (now-deleted) detail view.
          context.read<SalesBloc>().add(const GetSalesEvent());
          Navigator.pop(context);
        }
      },
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          List<Widget>? extraActions;
          // Chek yuklab olish faqat sales.invoice ruxsati bilan ko'rinadi.
          final canInvoice = Provider.of<AuthProvider>(
            context,
            listen: false,
          ).can(Permissions.salesInvoice);
          if (state is SaleDetailLoaded && canInvoice) {
            extraActions = [
              IconButton(
                icon: Icon(Icons.download, color: context.colors.text),
                onPressed: () => _downloadPdf(state.sale),
                tooltip: l10n.downloadPdf,
              ),
            ];
          }

          final isDraft =
              state is SaleDetailLoaded &&
              (state.sale['status']?.toString().toLowerCase() == 'draft');

          return NetworkWrapper(
            onRetry: _loadSaleDetails,
            child: Scaffold(
              backgroundColor: context.colors.bg,
              appBar: CommonAppBar(
                title: l10n.sales,
                onRefresh: _loadSaleDetails,
                onBackPressed: () {
                  context.read<SalesBloc>().add(const GetSalesEvent());
                  Navigator.pop(context);
                },
                extraActions: extraActions,
              ),
              body: _buildBody(state, l10n),
              floatingActionButton: isDraft
                  ? FloatingActionButton.extended(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ContinueSaleScreen(saleId: widget.saleId),
                          ),
                        );
                        if (result == true && mounted) _loadSaleDetails();
                      },
                      backgroundColor: AppColors.info,
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        l10n.ongoing,
                        style: AppTextStyles.labelLarge().copyWith(
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Two-step confirmation before a destructive delete. On confirm, dispatches
  /// DeleteSaleEvent; the BlocListener above handles success (snackbar + pop).
  Future<void> _confirmAndDeleteSale(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.confirmDeleteTitle,
                style: AppTextStyles.titleMedium(),
              ),
            ),
          ],
        ),
        content: Text(
          '${l10n.deleteSaleConfirm}\n\n'
          '${l10n.warning} Ombor va kassa avtomatik qaytariladi.',
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<SalesBloc>().add(DeleteSaleEvent(saleId: widget.saleId));
    }
  }

  Widget _buildBody(SalesState state, AppLocalizations l10n) {
    if (state is SaleDetailLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
        ),
      );
    }
    if (state is SaleDetailLoaded) {
      final sale = state.sale;
      final status = sale['status']?.toString() ?? '';
      final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final paidAmount = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final remainingAmount = totalAmount - paidAmount;
      final items = sale['items'] as List<dynamic>? ?? [];

      final canEditSales = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).can(Permissions.salesEdit);
      final canInvoice = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).can(Permissions.salesInvoice);
      final statusLower = status.toLowerCase();
      final canReturn =
          canEditSales &&
          (statusLower == 'paid' ||
              statusLower == 'debt' ||
              statusLower == 'closed');

      // Owner data-cleanup: delete a wrongly-entered sale. Gated by the
      // sales.delete permission (Owner/SuperAdmin always pass). Backend allows
      // Draft/Paid/Debt only — mirror that here so the button isn't offered for
      // terminal (cancelled/closed) sales.
      final canDelete =
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).can(Permissions.salesDelete) &&
          (statusLower == 'draft' ||
              statusLower == 'paid' ||
              statusLower == 'debt');

      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              100,
            ),
            child: Column(
              children: [
                SaleMetaCard(sale: sale, status: status),
                const SizedBox(height: AppSpacing.lg),
                SaleReceiptCard(
                  items: items,
                  total: totalAmount,
                  paid: paidAmount,
                  remaining: remainingAmount,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (canInvoice) ...[
                  SaleActionTiles(onPrint: () => _printInvoice(sale)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (canReturn)
                  AppDangerButton(
                    label: l10n.returnAction,
                    icon: Icons.keyboard_return_rounded,
                    onPressed: () =>
                        showRefundPicker(context, items, widget.saleId),
                  ),
                if (canDelete) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppDangerButton(
                    label: l10n.deleteSale,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _confirmAndDeleteSale(l10n),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Center(
      child: Text(l10n.errorOccurred, style: AppTextStyles.bodyMedium()),
    );
  }
}
