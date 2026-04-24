import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
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
            backgroundColor: Colors.red,
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
                backgroundColor: Colors.orange,
              ));
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.pdfDownloaded),
                backgroundColor: Colors.green,
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
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      // Xatolik bo'lsa
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.errorOccurred}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = widget.saleDetails['saleItems'] as List<dynamic>? ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← content baqadar
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          _buildHeader(context, theme, isDark, l10n),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // max 60%
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTile(Icons.person_outline, l10n.customer,
                      widget.sale.customerName ?? l10n.anonymousCustomer, theme),
                  _buildInfoTile(
                      Icons.account_balance_wallet_outlined,
                      l10n.paymentType,
                      _getPaymentText(widget.sale.paymentType, l10n),
                      theme),
                  const SizedBox(height: 20),
                  Text(l10n.products,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...items.map(
                      (item) => _buildProductItem(item, theme, isDark, l10n)),
                  const SizedBox(height: 24),
                  _buildTotalsCard(theme, l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark,
      AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.saleDetail,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(DateFormat('dd.MM.yyyy HH:mm').format(widget.sale.createdAt),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                tooltip: l10n.downloadPdf,
                style: IconButton.styleFrom(
                    backgroundColor: theme.primaryColor.withOpacity(0.1)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                    backgroundColor: theme.dividerColor.withOpacity(0.1)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      dynamic item, ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? l10n.unknown,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${item['quantity']} x ${item['unitPrice']}",
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text("${item['totalPrice']} ${l10n.currencySom}",
              style: TextStyle(
                  color: theme.primaryColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _totalRow(l10n.totalSum, "${widget.sale.totalAmount} ${l10n.currencySom}",
              Colors.white),
          if (widget.isOwner && widget.sale.profit != null) ...[
            const Divider(color: Colors.white24, height: 20),
            _totalRow(l10n.profit, "+${widget.sale.profit} ${l10n.currencySom}",
                Colors.greenAccent),
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
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w900)),
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
