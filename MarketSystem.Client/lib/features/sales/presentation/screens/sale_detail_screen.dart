import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/auth/permissions.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/sales/presentation/screens/continue_sale_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..download = fileName
          ..style.display = 'none';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else if (Platform.isAndroid || Platform.isIOS) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } else {
        Directory? directory;
        if (Platform.isWindows) {
          final username = Platform.environment['USERNAME'] ?? 'User';
          directory = Directory('C:/Users/$username/Downloads');
        } else if (Platform.isMacOS || Platform.isLinux) {
          directory = await getDownloadsDirectory();
        }

        final path = '${directory?.path ?? '.'}/$fileName';
        final file = File(path);

        if (directory != null && !directory.existsSync()) {
          await directory.create(recursive: true);
        }
        await file.writeAsBytes(pdfBytes);

        if (mounted) Navigator.pop(context);

        if (mounted) {
          final result = await OpenFilex.open(path);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.errorOccurred}: ${result.message}'),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pdfDownloaded),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        }
        return;
      }

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfDownloaded),
            backgroundColor: AppColors.success,
          ),
        );
      }
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
        }
      },
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          List<Widget>? extraActions;
          if (state is SaleDetailLoaded) {
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
                      backgroundColor: const Color(0xFF3B82F6),
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
      final statusLower = status.toLowerCase();
      final canReturn =
          canEditSales &&
          (statusLower == 'paid' ||
              statusLower == 'debt' ||
              statusLower == 'closed');

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
                SaleActionTiles(onDownloadPdf: () => _downloadPdf(sale)),
                const SizedBox(height: AppSpacing.lg),
                if (canReturn)
                  AppDangerButton(
                    label: l10n.returnAction,
                    icon: Icons.keyboard_return_rounded,
                    onPressed: () =>
                        showRefundPicker(context, items, widget.saleId),
                  ),
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
