import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../data/services/sales_service.dart';
import '../../../core/providers/auth_provider.dart';

class SaleDetailSheet extends StatefulWidget {
  final dynamic sale;
  final Map<String, dynamic> saleDetails;
  final bool isOwner;

  const SaleDetailSheet({
    super.key,
    required this.sale,
    required this.saleDetails,
    required this.isOwner,
  });

  @override
  State<SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<SaleDetailSheet> {
  late final SalesService _salesService;

  @override
  void initState() {
    super.initState();
    _salesService = SalesService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
  }

  Future<void> _downloadPdf() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final saleId = widget.sale.id?.toString() ?? '';

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
      final pdfData = await _salesService.downloadInvoice(saleId);

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
      final createdAt = widget.sale.createdAt ?? DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy').format(createdAt);
      final fileName = 'faktura_${saleId}_$dateStr.pdf';

      // Platformaga qarab saqlash
      if (kIsWeb) {
        // Web: open the PDF in a new tab. Chrome / Edge / Firefox all have a
        // built-in PDF viewer, so the user sees the invoice immediately and
        // can print or save it from there. A silent download (anchor.click)
        // dumps the file into the Downloads folder with no visible feedback
        // and the user thinks nothing happened.
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        // Revoke after enough time for the new tab to fetch the blob.
        Future.delayed(const Duration(seconds: 30),
            () => html.Url.revokeObjectUrl(url));
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

  @override
  Widget build(BuildContext context) {
    // Backend's GetSaleById returns `items`, not `saleItems`. Reading the
    // wrong key meant the products section in the detail sheet rendered
    // empty for every sale. Try both keys for back-compat.
    final items = (widget.saleDetails['items'] as List<dynamic>? ??
        widget.saleDetails['saleItems'] as List<dynamic>? ??
        const []);
    final sellerName = (widget.saleDetails['sellerName'] as String?) ??
        widget.sale.sellerName;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← content baqadar
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          _buildHeader(context, l10n),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // max 60%
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTile(context, Icons.person_outline, l10n.customer,
                      widget.sale.customerName ?? l10n.anonymousCustomer),
                  _buildInfoTile(
                      context, Icons.badge_outlined, l10n.seller, sellerName),
                  _buildInfoTile(
                      context,
                      Icons.account_balance_wallet_outlined,
                      l10n.paymentType,
                      _getPaymentText(widget.sale.paymentType, l10n)),
                  const SizedBox(height: AppSpacing.xl2),
                  Text(l10n.products,
                      style: AppTextStyles.titleMedium()
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: AppSpacing.md),
                  ...items.map((item) => _buildProductItem(context, item, l10n)),
                  const SizedBox(height: AppSpacing.xl3),
                  _buildTotalsCard(context, l10n),
                  const SizedBox(height: AppSpacing.xl2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl2, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.saleDetail,
                  style: AppTextStyles.titleLarge().copyWith(fontSize: 20)),
              Text(DateFormat('dd.MM.yyyy HH:mm').format(widget.sale.createdAt),
                  style: AppTextStyles.bodySmall()),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _downloadPdf,
                icon: Icon(Icons.download, color: context.colors.brand),
                tooltip: l10n.downloadPdf,
                style: IconButton.styleFrom(
                    backgroundColor: context.colors.brandLight),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded,
                    color: context.colors.textSecondary),
                style: IconButton.styleFrom(
                    backgroundColor: context.colors.inputFill),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.brand),
          const SizedBox(width: AppSpacing.lg),
          Text('$label: ',
              style: AppTextStyles.bodySmall()
                  .copyWith(color: context.colors.textSecondary)),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium()
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      BuildContext context, dynamic item, AppLocalizations l10n) {
    final isExternal = item['isExternal'] == true;
    // Comment is what the seller typed in the price-input sheet
    // ("description" in the user's words). API returns it as `comment`.
    final comment = (item['comment'] as String?)?.trim() ?? '';
    // Price column can come as either `salePrice` or `unitPrice` depending
    // on which endpoint produced the row — handle both.
    final unitPrice = (item['salePrice'] ?? item['unitPrice'] ?? 0).toString();
    final qty = (item['quantity'] ?? 0).toString();
    final totalPrice = (item['totalPrice'] ??
            ((item['quantity'] as num?) ?? 0) *
                ((item['salePrice'] as num?) ?? 0))
        .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isExternal
            ? Border.all(
                color: context.colors.brand.withValues(alpha: 0.4), width: 1)
            : Border.all(color: context.colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item['productName']?.toString() ?? l10n.unknown,
                            style: AppTextStyles.labelLarge()
                                .copyWith(fontSize: 14),
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
                            child: Text(
                              'tashqi',
                              style: AppTextStyles.caption().copyWith(
                                fontSize: 9,
                                color: context.colors.brandDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$qty × $unitPrice',
                        style: AppTextStyles.bodySmall()),
                  ],
                ),
              ),
              Text(
                '$totalPrice ${l10n.currencySom}',
                style: AppTextStyles.labelLarge().copyWith(
                  color: context.colors.brand,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
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
                    child: Text(
                      comment,
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.colors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.brand, context.colors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          _totalRow(l10n.totalSum,
              '${widget.sale.totalAmount} ${l10n.currencySom}', Colors.white),
          if (widget.isOwner && widget.sale.profit != null) ...[
            const Divider(color: Colors.white24, height: AppSpacing.xl2),
            _totalRow(
                l10n.profit,
                '+${widget.sale.profit} ${l10n.currencySom}',
                AppColors.successLight),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium().copyWith(
              color: color.withValues(alpha: 0.85),
            )),
        Text(value,
            style: AppTextStyles.titleMedium().copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            )),
      ],
    );
  }

  String _getPaymentText(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'cash':
        return l10n.cash;
      case 'card':
        return '${l10n.card} / ${l10n.terminal}';
      default:
        return type;
    }
  }
}
