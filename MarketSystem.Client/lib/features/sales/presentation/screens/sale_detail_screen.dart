import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import 'package:market_system_client/core/auth/permissions.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/features/sales/presentation/screens/continue_sale_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/events/sales_event.dart';
import '../bloc/states/sales_state.dart';

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

  /// PDF yuklab olish (server-side)
  Future<void> _downloadPdf(Map<String, dynamic> sale) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    // Loading dialog ko'rsatish
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
      // PDFni serverdan yuklab olish
      final pdfData = await _salesService.downloadInvoice(widget.saleId);

      if (pdfData == null || pdfData.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.errorOccurred),
            backgroundColor: AppColors.danger,
          ));
        }
        return;
      }

      // List<int> -> Uint8List ga o'tkazish
      final pdfBytes = Uint8List.fromList(pdfData);

      // Fayl nomini generatsiya qilish
      final createdAt = sale['createdAt'] != null
          ? (sale['createdAt'] is DateTime
              ? sale['createdAt'] as DateTime
              : DateTime.parse(sale['createdAt'].toString()))
          : DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy').format(createdAt);
      final fileName = 'faktura_${widget.saleId}_$dateStr.pdf';

      // Platformaga qarab saqlash
      if (kIsWeb) {
        // Web platformada browser download API orqali yuklash
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
        // Mobile platformlarda printing orqali yuklash
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      } else {
        // Desktop platformlarda
        Directory? directory;
        if (Platform.isWindows) {
          final username = Platform.environment['USERNAME'] ?? 'User';
          directory = Directory('C:/Users/$username/Downloads');
        } else if (Platform.isMacOS || Platform.isLinux) {
          directory = await getDownloadsDirectory();
        }

        final path = '${directory?.path ?? '.'}/$fileName';
        final file = File(path);

        // Directory mavjudligini tekshirish va yaratish
        if (directory != null && !directory.existsSync()) {
          await directory.create(recursive: true);
        }

        await file.writeAsBytes(pdfBytes);

        // Dialogni yopish
        if (mounted) Navigator.pop(context);

        // Desktop'da faylni ochish
        if (mounted) {
          final result = await OpenFilex.open(path);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${l10n.errorOccurred}: ${result.message}'),
                backgroundColor: AppColors.warning,
              ));
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.pdfDownloaded),
                backgroundColor: AppColors.success,
              ));
            }
          }
        }
        return;
      }

      // Dialogni yopish
      if (mounted) Navigator.pop(context);

      // Muvaffaqiyat xabari
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.pdfDownloaded),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      // Xatolik bo'lsa
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.errorOccurred}: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'debt':
        return AppColors.danger;
      case 'draft':
        return AppColors.warning;
      case 'closed':
        return const Color(0xFF6366F1);
      default:
        return context.colors.textMuted;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'paid':
        return l10n.paid;
      case 'debt':
        return l10n.debt;
      case 'draft':
        return l10n.ongoing;
      case 'closed':
        return l10n.closed;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger));
        } else if (state is SaleItemReturned) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.returnSuccess),
              backgroundColor: AppColors.success));
          _loadSaleDetails();
        }
      },
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          // State asosida extraActions aniqlash
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

          // Show a "Davom etish" FAB only for in-progress (Draft) sales
          // so the seller can pick up where they left off — adding more
          // items, comments, or completing the sale.
          final isDraft = state is SaleDetailLoaded &&
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
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white),
                      label: Text(
                        l10n.ongoing,
                        style: AppTextStyles.labelLarge()
                            .copyWith(color: Colors.white),
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(context.colors.brand)));
    }
    if (state is SaleDetailLoaded) {
      final sale = state.sale;
      final status = sale['status']?.toString() ?? '';
      final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final paidAmount = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final remainingAmount = totalAmount - paidAmount;
      final items = sale['items'] as List<dynamic>? ?? [];

      // Refund control: returning an item is a sales.edit capability —
      // matches the backend [RequirePermission(sales.edit)] on
      // /Sales/{id}/return-item. Sellers lack it by default.
      final canEditSales =
          Provider.of<AuthProvider>(context, listen: false)
              .can(Permissions.salesEdit);
      final statusLower = status.toLowerCase();
      final canReturn = canEditSales &&
          (statusLower == 'paid' ||
              statusLower == 'debt' ||
              statusLower == 'closed');

      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 100),
            child: Column(
              children: [
                _buildMetaCard(sale, l10n, status),
                const SizedBox(height: AppSpacing.lg),
                _buildReceiptCard(
                    items, totalAmount, paidAmount, remainingAmount, l10n),
                const SizedBox(height: AppSpacing.lg),
                _buildActionTiles(l10n, sale),
                const SizedBox(height: AppSpacing.lg),
                if (canReturn)
                  AppDangerButton(
                    label: l10n.returnAction,
                    icon: Icons.keyboard_return_rounded,
                    onPressed: () => _showRefundPicker(items),
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

  /// Meta card matching demo's `.detail-meta-card` — soft `#F8FAFC` bg + a
  /// stack of label/value rows.
  Widget _buildMetaCard(
      Map<String, dynamic> sale, AppLocalizations l10n, String status) {
    final color = _getStatusColor(status);
    final paymentType = sale['paymentType']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSoft),
      ),
      child: Column(
        children: [
          _metaRow(l10n.seller, sale['sellerName']?.toString() ?? l10n.unknown,
              context.colors.text),
          _metaDivider(),
          _metaRow(
            l10n.dateTimeLabel,
            DateFormat('dd.MM.yyyy HH:mm').format(
              sale['createdAt'] is DateTime
                  ? sale['createdAt'] as DateTime
                  : DateTime.parse(sale['createdAt'].toString()),
            ),
            context.colors.text,
          ),
          if (paymentType != null && paymentType.isNotEmpty) ...[
            _metaDivider(),
            _metaRow(
              l10n.paymentType,
              _paymentLabel(paymentType, l10n),
              context.colors.text,
            ),
          ],
          if (sale['customerName'] != null) ...[
            _metaDivider(),
            _metaRow(l10n.customer, sale['customerName'].toString(),
                context.colors.text),
          ],
          _metaDivider(),
          _metaRow(
            l10n.statusLabel,
            _statusLabel(status, l10n),
            color,
            valueWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, Color valueColor,
      {FontWeight? valueWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall()
                    .copyWith(color: context.colors.textSecondary)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium().copyWith(
                color: valueColor,
                fontWeight: valueWeight ?? FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaDivider() => Container(
        height: 1,
        color: context.colors.border.withValues(alpha: 0.6),
      );

  String _paymentLabel(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'cash':
        return l10n.cash;
      case 'card':
        return l10n.card;
      case 'terminal':
        return l10n.terminal;
      case 'debt':
        return l10n.debt;
      default:
        return type;
    }
  }

  /// Receipt block with dashed border + items + totals (matches demo's
  /// `.receipt-block`).
  Widget _buildReceiptCard(List<dynamic> items, double total, double paid,
      double remaining, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: context.colors.border,
          radius: AppRadius.lg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 18, color: context.colors.textSecondary),
                  8.width,
                  Text(l10n.products,
                      style: AppTextStyles.labelLarge().copyWith(fontSize: 14)),
                  const Spacer(),
                  Text('${items.length}',
                      style: AppTextStyles.labelSmall()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...items.map((item) => _buildReceiptLine(item, l10n)),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 1,
                color: context.colors.border,
              ),
              const SizedBox(height: AppSpacing.lg),
              _totalsRow(l10n.totalSum, NumberFormatter.format(total),
                  emphasize: false),
              const SizedBox(height: AppSpacing.md),
              _totalsRow(l10n.paid, NumberFormatter.format(paid),
                  emphasize: true, valueColor: AppColors.success),
              if (remaining > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _totalsRow(l10n.debt, NumberFormatter.format(remaining),
                    emphasize: false, valueColor: AppColors.danger),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptLine(Map<String, dynamic> item, AppLocalizations l10n) {
    final qty = (item['quantity'] as num).toDouble();
    final price = (item['salePrice'] as num).toDouble();
    final isExternal = item['isExternal'] == true;
    final comment = (item['comment'] as String?)?.trim() ?? '';

    final unitName = (item['unit'] ?? '').toString().toLowerCase();
    const weightUnits = ['kg', 'кг', 'kilogram', 'g', 'gr', 'litr', 'l', 'л'];
    final isWeight = weightUnits.contains(unitName);
    final qtyDisplay = isWeight ? qty.toString() : qty.toInt().toString();
    final unit = item['unit'] ?? l10n.piece;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item['productName'] ?? l10n.unknown,
                            style: AppTextStyles.labelLarge()
                                .copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExternal) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandTint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(l10n.externalTag,
                                style: AppTextStyles.caption().copyWith(
                                  color: context.colors.brandDark,
                                  fontSize: 9,
                                )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qtyDisplay $unit × ${NumberFormatter.format(price)}',
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(NumberFormatter.format(item['totalPrice']),
                  style: AppTextStyles.labelLarge().copyWith(fontSize: 14)),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      size: 13, color: context.colors.brandDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(comment,
                        style: AppTextStyles.bodySmall().copyWith(
                          fontSize: 12,
                          color: context.colors.text,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalsRow(String label, String value,
      {required bool emphasize, Color? valueColor}) {
    final labelStyle = emphasize
        ? AppTextStyles.labelLarge()
        : AppTextStyles.bodyMedium()
            .copyWith(color: context.colors.textSecondary);
    final valueStyle = emphasize
        ? AppTextStyles.titleMedium().copyWith(
            color: valueColor ?? context.colors.text,
            fontSize: 16,
          )
        : AppTextStyles.bodyMedium().copyWith(
            color: valueColor ?? context.colors.text,
            fontWeight: FontWeight.w700,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  /// Action tiles (print + SMS) matching demo's `.action-grid`.
  Widget _buildActionTiles(AppLocalizations l10n, Map<String, dynamic> sale) {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.print_outlined,
            label: l10n.printAction,
            onTap: () => _downloadPdf(sale),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _actionTile(
            icon: Icons.sms_outlined,
            label: l10n.sendSms,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.comingSoon),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
          child: Column(
            children: [
              Icon(icon, color: context.colors.brand, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style:
                      AppTextStyles.labelLarge().copyWith(fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Refund flow ───────────────────────────

  /// Picks an item to refund from the receipt, then opens the quantity sheet.
  /// One sheet per item keeps the API call surface unchanged
  /// (`ReturnSaleItemEvent` operates on a single saleItemId).
  void _showRefundPicker(List<dynamic> items) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: const Border(
                  left: BorderSide(color: AppColors.warning, width: 3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.returnWarning,
                      style:
                          AppTextStyles.bodySmall().copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.whichProductReturning,
                style: AppTextStyles.caption()),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final item = items[i] as Map<String, dynamic>;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showReturnBottomSheet(item);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.colors.bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName']?.toString() ??
                                      l10n.unknown,
                                  style: AppTextStyles.labelLarge()
                                      .copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.soldQtyFormat(item['quantity'], NumberFormatter.format(item['salePrice'])),
                                  style: AppTextStyles.bodySmall(),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: context.colors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnBottomSheet(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final productName = item['productName'] ?? l10n.unknownProduct;
    final saleItemId = item['id']?.toString() ?? '';
    final maxQuantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;

    final quantityController = TextEditingController(text: '1');
    final commentController = TextEditingController();
    final l10nOuter = AppLocalizations.of(context)!;
    String selectedReason = l10nOuter.returnReasonBad;
    String selectedMethod = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final qtyText = quantityController.text
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll(',', '.');
          double currentQty = double.tryParse(qtyText) ?? 0.0;
          double returnSum = currentQty * salePrice;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              top: AppSpacing.xl,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  20.height,
                  Row(
                    children: [
                      const Icon(Icons.keyboard_return_rounded,
                          color: AppColors.danger, size: 24),
                      const SizedBox(width: AppSpacing.lg),
                      Text(l10n.processReturn,
                          style: AppTextStyles.titleMedium()),
                    ],
                  ),
                  16.height,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: const Border(
                        left: BorderSide(color: AppColors.warning, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.returnWarning,
                            style: AppTextStyles.bodySmall()
                                .copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  16.height,
                  Text(productName,
                      style: AppTextStyles.labelLarge().copyWith(fontSize: 14)),
                  4.height,
                  Text('${l10n.maxReturn}: $maxQuantity ${l10n.piece}',
                      style: AppTextStyles.bodySmall()
                          .copyWith(color: AppColors.warning)),
                  16.height,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _fieldLabel(
                            l10n.amount,
                            TextField(
                              controller: quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (v) => setSheetState(() {}),
                              decoration: _inputStyle('1',
                                  suffix: l10n.piece),
                            )),
                      ),
                    ],
                  ),
                  16.height,
                  Text(l10n.reasonLabel, style: AppTextStyles.caption()),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      l10n.returnReasonBad,
                      l10n.returnReasonExpired,
                      l10n.returnReasonDisliked,
                      l10n.returnReasonOther,
                    ].map((reason) {
                      final sel = selectedReason == reason;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedReason = reason),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: sel
                                ? context.colors.text
                                : context.colors.inputFill,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            reason,
                            style: AppTextStyles.labelSmall().copyWith(
                              color: sel
                                  ? Colors.white
                                  : context.colors.text,
                              fontSize: 12,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  16.height,
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration:
                        _inputStyle(l10n.additionalCommentHint),
                  ),
                  16.height,
                  Text(l10n.returnMethodLabel, style: AppTextStyles.caption()),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _methodTile(
                          icon: Icons.payments_outlined,
                          title: l10n.cashReturn,
                          subtitle: l10n.toCustomerHere,
                          selected: selectedMethod == 'cash',
                          onTap: () =>
                              setSheetState(() => selectedMethod = 'cash'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _methodTile(
                          icon: Icons.assignment_outlined,
                          title: l10n.toBalance,
                          subtitle: l10n.forNextSale,
                          selected: selectedMethod == 'balance',
                          onTap: () =>
                              setSheetState(() => selectedMethod = 'balance'),
                        ),
                      ),
                    ],
                  ),
                  16.height,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(l10n.toReturnLabel,
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.danger)),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormatter.format(returnSum)} UZS',
                          style: AppTextStyles.displayMedium()
                              .copyWith(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                  16.height,
                  AppDangerButton(
                    label: l10n.confirmAndReturn,
                    icon: Icons.keyboard_return_rounded,
                    onPressed: () {
                      final qtyText = quantityController.text
                          .replaceAll(RegExp(r'\s+'), '')
                          .replaceAll(',', '.');
                      final qty = double.tryParse(qtyText);
                      if (qty == null || qty <= 0 || qty > maxQuantity) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(l10n.invalidQuantity),
                            backgroundColor: AppColors.danger));
                        return;
                      }
                      Navigator.pop(ctx);
                      // Compose reason + free-form note into a single comment
                      // — the API currently accepts one `comment` field.
                      final note = commentController.text.trim();
                      final combined =
                          note.isEmpty ? selectedReason : '$selectedReason — $note';
                      context.read<SalesBloc>().add(ReturnSaleItemEvent(
                            saleId: widget.saleId,
                            saleItemId: saleItemId,
                            quantity: qty,
                            comment: combined,
                          ));
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSecondaryButton(
                    label: l10n.cancel,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _methodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.brandLight
              : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color:
                selected ? context.colors.brand : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.colors.brand, size: 22),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: AppTextStyles.labelLarge().copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.bodySmall()),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall()),
        8.height,
        child,
      ],
    );
  }

  InputDecoration _inputStyle(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium()
          .copyWith(color: context.colors.textMuted),
      suffixText: suffix,
      suffixStyle: AppTextStyles.bodySmall(),
      filled: true,
      fillColor: context.colors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
    );
  }
}

/// Lightweight dashed-border painter used for the receipt card outline.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    const dashLen = 4.0;
    const gapLen = 3.0;
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLen).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
