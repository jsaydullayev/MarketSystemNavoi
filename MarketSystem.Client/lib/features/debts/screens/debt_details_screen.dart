import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/debts/widgets/debt_summary_header.dart';
import 'package:market_system_client/features/debts/widgets/edit_price_bottomsheet.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/providers/auth_provider.dart';
import '../../../data/services/sales_service.dart';

class DebtDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> debt;
  final String customerName;

  const DebtDetailsScreen({
    super.key,
    required this.debt,
    required this.customerName,
  });

  @override
  State<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends State<DebtDetailsScreen> {
  bool _isLoading = false;
  List<dynamic> _saleItems = [];
  late final SalesService _salesService;

  @override
  void initState() {
    super.initState();
    _salesService = SalesService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _loadSaleDetails();
  }

  Future<void> _downloadPdf() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final lang = Localizations.localeOf(context).languageCode;

    final saleId = widget.debt['saleId']?.toString() ?? '';

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfData = await _salesService.downloadInvoice(saleId, lang: lang);

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

      final pdfBytes = Uint8List.fromList(pdfData);

      final createdAt = widget.debt['createdAt'] != null
          ? (widget.debt['createdAt'] is DateTime
              ? widget.debt['createdAt'] as DateTime
              : DateTime.parse(widget.debt['createdAt'].toString()))
          : DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy').format(createdAt);
      final fileName = 'faktura_${saleId}_$dateStr.pdf';

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

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.pdfDownloaded),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.errorOccurred}: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _loadSaleDetails() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _saleItems = widget.debt['saleItems'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('Xatolik: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _openEditSheet(dynamic saleItem) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final debtStatus = widget.debt['status'];

    if (debtStatus == 'Closed' && userRole != 'Owner' && userRole != 'Admin') {
      _showError(l10n.noPermissionToEditClosed);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPriceBottomSheet(
        saleItem: saleItem,
        debtStatus: debtStatus,
        userRole: userRole,
        onSave: (newPrice, comment) async {
          await _updatePrice(saleItem, newPrice, comment);
        },
      ),
    );
  }

  Future<void> _updatePrice(
      dynamic saleItem, double newPrice, String comment) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final saleService = SalesService(authProvider: authProvider);
      await saleService.updateSaleItemPrice(
        saleItemId: saleItem['id'],
        newPrice: newPrice,
        comment: comment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.priceUpdatedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSaleDetails();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('${l10n.error}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?['role'];
    final debtStatus = widget.debt['status'];
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadSaleDetails,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(
          title: l10n.debtDetails,
          extraActions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
              tooltip: l10n.downloadPdf,
            ),
          ],
        ),
        body: Column(
          children: [
            DebtSummaryHeader(
              customerName: widget.customerName,
              debt: widget.debt,
              debtStatus: debtStatus,
              l10n: l10n,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _saleItems.isEmpty
                      ? const _EmptySaleItemsView()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl3),
                          itemCount: _saleItems.length,
                          itemBuilder: (context, index) {
                            final item = _saleItems[index];
                            return _SaleItemCard(
                              item: item,
                              userRole: userRole,
                              debtStatus: debtStatus,
                              onEdit: () => _openEditSheet(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleItemCard extends StatelessWidget {
  final dynamic item;
  final String? userRole;
  final String debtStatus;
  final VoidCallback onEdit;

  const _SaleItemCard({
    required this.item,
    required this.userRole,
    required this.debtStatus,
    required this.onEdit,
  });

  bool get _canEdit {
    if (debtStatus == 'Open') return userRole != null;
    return userRole == 'Owner' || userRole == 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productName = item['productName'] ?? l10n.unknown;
    final isExternal = item['isExternal'] == true;
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num).toDouble();
    final totalPrice = salePrice * quantity;
    // "Description" the user types in the price-input sheet — the API
    // returns it as `comment`.
    final comment = (item['comment'] as String?)?.trim() ?? '';

    final accent = isExternal ? context.colors.brand : context.colors.text;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isExternal
              ? context.colors.brand.withValues(alpha: 0.35)
              : context.colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: (isExternal ? context.colors.brand : context.colors.text)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Icon(
                  isExternal
                      ? Icons.storefront_rounded
                      : Icons.inventory_2_rounded,
                  color: isExternal ? context.colors.brand : context.colors.text,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            productName,
                            style: AppTextStyles.bodyMedium().copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExternal) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.brand.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              'tashqi',
                              style: AppTextStyles.caption().copyWith(
                                color: context.colors.brand,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${quantity.toStringAsFixed(0)} ${l10n.piece} × ${NumberFormatter.format(salePrice)} ${l10n.currencySom}',
                      style: AppTextStyles.bodySmall()
                          .copyWith(fontSize: 12, color: context.colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormatter.format(totalPrice)} ${l10n.currencySom}',
                    style: AppTextStyles.titleMedium().copyWith(
                      fontSize: 15,
                      color: accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (_canEdit) ...[
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md + 2,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: context.colors.brandLight,
                          borderRadius: BorderRadius.circular(AppRadius.md - 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 12, color: context.colors.brand),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.edit,
                              style: AppTextStyles.bodySmall().copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.colors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md + 2),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2, vertical: 7),
              decoration: BoxDecoration(
                color: context.colors.borderSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      size: 14, color: context.colors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      comment,
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        height: 1.3,
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
}

class _EmptySaleItemsView extends StatelessWidget {
  const _EmptySaleItemsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 52, color: context.colors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.noProducts,
              style: AppTextStyles.titleMedium()
                  .copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
