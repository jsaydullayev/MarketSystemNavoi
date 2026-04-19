import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Faktura PDF generatsiya qilish uchun xizmat
/// Savdo ma'lumotlarini PDF formatida generatsiya qiladi
class InvoicePdfGenerator {
  /// PDF generatsiya qilish
  static Future<Uint8List> generateInvoice(Map<String, dynamic> sale) async {
    // Fontlarni yuklash
    final regularFont = await _loadFont('assets/fonts/Roboto-Regular.ttf');
    final boldFont = await _loadFont('assets/fonts/Roboto-Bold.ttf');

    final pdf = pw.Document();

    // Savdo ma'lumotlarini olish
    final saleId = sale['id']?.toString() ?? 'N/A';
    final customerName = sale['customerName']?.toString() ?? 'Mijoz kiritilmagan';
    final customerPhone = sale['customerPhone']?.toString();
    final sellerName = sale['sellerName']?.toString() ?? 'Noma\'lum';
    final totalAmount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = totalAmount - paidAmount;
    final status = sale['status']?.toString() ?? 'unknown';
    final createdAt = sale['createdAt'] != null
        ? (sale['createdAt'] is DateTime
            ? sale['createdAt'] as DateTime
            : DateTime.parse(sale['createdAt'].toString()))
        : DateTime.now();
    final items = sale['items'] as List<dynamic>? ?? [];

    // Sana formatlash
    final formattedDate = DateFormat('dd.MM.yyyy').format(createdAt);
    final formattedTime = DateFormat('HH:mm').format(createdAt);

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(boldFont, regularFont),
              pw.SizedBox(height: 20),

              // Faktura ma'lumotlari
              _buildInvoiceInfo(saleId, formattedDate, formattedTime, boldFont, regularFont),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Mijoz va Sotuvchi ma'lumotlari
              _buildCustomerSellerInfo(customerName, customerPhone, sellerName, regularFont, boldFont),

              pw.SizedBox(height: 24),

              // Mahsulotlar jadvali
              _buildProductsTable(items, boldFont, regularFont),

              pw.SizedBox(height: 24),

              // Jami ma'lumotlar
              _buildTotalSection(totalAmount, paidAmount, remainingAmount, status, boldFont, regularFont),

              // Footer
              pw.SizedBox(height: 40),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              _buildFooter(regularFont),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Header qismi
  static pw.Widget _buildHeader(pw.Font boldFont, pw.Font regularFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'strotech 🚀',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 24,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Savdo Tizimi',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Text(
            'FAKTURA',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: PdfColors.blue800,
            ),
          ),
        ),
      ],
    );
  }

  /// Faktura ma'lumotlari
  static pw.Widget _buildInvoiceInfo(
    String saleId,
    String date,
    String time,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Faktura №:',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                saleId,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Sana:',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                '$date | $time',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mijoz va Sotuvchi ma'lumotlari
  static pw.Widget _buildCustomerSellerInfo(
    String customerName,
    String? customerPhone,
    String sellerName,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('👤 Mijoz:', customerName, regularFont, boldFont),
        if (customerPhone != null && customerPhone.isNotEmpty)
          pw.SizedBox(height: 8),
        if (customerPhone != null && customerPhone.isNotEmpty)
          _buildInfoRow('📱 Telefon:', customerPhone, regularFont, boldFont),
        pw.SizedBox(height: 8),
        _buildInfoRow('💼 Sotuvchi:', sellerName, regularFont, boldFont),
      ],
    );
  }

  /// Ma'lumotlar qatori
  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Mahsulotlar jadvali
  static pw.Widget _buildProductsTable(
    List<dynamic> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Mahsulotlar ro\'yxati',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
          ),
        ),
        pw.SizedBox(height: 12),

        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 1,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Mahsulot nomi
            1: const pw.FlexColumnWidth(1), // Soni
            2: const pw.FlexColumnWidth(1.5), // Narxi
            3: const pw.FlexColumnWidth(1.5), // Jami
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('Mahsulot', boldFont, isHeader: true),
                _buildTableCell('Soni', boldFont, isHeader: true),
                _buildTableCell('Narxi', boldFont, isHeader: true),
                _buildTableCell('Jami', boldFont, isHeader: true),
              ],
            ),
            // Product rows
            for (var item in items)
              pw.TableRow(
                children: [
                  _buildTableCell(item['productName']?.toString() ?? 'Noma\'lum', regularFont),
                  _buildTableCell(
                    '${(item['quantity'] as num?)?.toDouble() ?? 0.0} ${item['unit']?.toString() ?? 'dona'}',
                    regularFont,
                  ),
                  _buildTableCell(
                    _formatPrice((item['salePrice'] as num?)?.toDouble() ?? 0.0),
                    regularFont,
                  ),
                  _buildTableCell(
                    _formatPrice((item['totalPrice'] as num?)?.toDouble() ?? ((item['quantity'] as num?)?.toDouble() ?? 0.0) * ((item['salePrice'] as num?)?.toDouble() ?? 0.0)),
                    regularFont,
                    isTotal: true,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// Jadval katakchasi
  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isTotal ? PdfColors.green800 : null,
        ),
        textAlign: isHeader || isTotal ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  /// Jami qismi
  static pw.Widget _buildTotalSection(
    double totalAmount,
    double paidAmount,
    double remainingAmount,
    String status,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('Jami summa:', totalAmount, boldFont, regularFont),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildMiniTotalRow('To\'langan:', paidAmount, regularFont, boldFont),
              ),
              pw.SizedBox(width: 20),
              pw.Container(width: 1, height: 40, color: PdfColors.blue200),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildMiniTotalRow('Qarz:', remainingAmount, regularFont, boldFont, isDebt: true),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 12),
          _buildStatusRow(status, boldFont),
        ],
      ),
    );
  }

  /// Jami qatori
  static pw.Widget _buildTotalRow(
    String label,
    double amount,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 14,
          ),
        ),
        pw.Text(
          _formatPrice(amount),
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 20,
            color: PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  /// Kichik jami qatori
  static pw.Widget _buildMiniTotalRow(
    String label,
    double amount,
    pw.Font regularFont,
    pw.Font boldFont, {
    bool isDebt = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _formatPrice(amount),
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
            color: isDebt && amount > 0 ? PdfColors.orange800 : PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  /// Holat qatori
  static pw.Widget _buildStatusRow(String status, pw.Font boldFont) {
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    // Rangni yorqinroq qilish uchun PdfColor.shade() ishlatamiz
    final statusBackgroundColor = _getLightColor(statusColor);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'To\'lov holati:',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: statusBackgroundColor,
            borderRadius: pw.BorderRadius.circular(20),
            border: pw.Border.all(color: statusColor, width: 1.5),
          ),
          child: pw.Text(
            statusText,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Footer
  static pw.Widget _buildFooter(pw.Font regularFont) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'strotech 🚀 - Savdo Tizimi',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: PdfColors.grey500,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Bu faktura elektron tarzda generatsiya qilingan',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: PdfColors.grey400,
            ),
          ),
        ),
      ],
    );
  }

  /// Fontni yuklash
  static Future<pw.Font> _loadFont(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }

  /// Yorqin rang yaratish (withOpacity o'rniga)
  static PdfColor _getLightColor(PdfColor color) {
    // PdfColor shaffoflikni qo'llab-quvvatlamaydi,
    // shuning uchun yorqinroq ranglar qaytaramiz
    if (color == PdfColors.green800) return PdfColors.green100;
    if (color == PdfColors.orange800) return PdfColors.orange100;
    if (color == PdfColors.amber800) return PdfColors.amber100;
    if (color == PdfColors.blue800) return PdfColors.blue100;
    if (color == PdfColors.red800) return PdfColors.red100;
    return PdfColors.grey100;
  }

  /// Narxni formatlash
  static String _formatPrice(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} so\'m';
  }

  /// Holat matni
  static String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'TO\'LANGAN';
      case 'debt':
        return 'QARZ';
      case 'draft':
        return 'CHERNOVIK';
      case 'closed':
        return 'YOPILGAN';
      case 'cancelled':
        return 'BEKOR QILINGAN';
      default:
        return status.toUpperCase();
    }
  }

  /// Holat rangi
  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColors.green800;
      case 'debt':
        return PdfColors.orange800;
      case 'draft':
        return PdfColors.amber800;
      case 'closed':
        return PdfColors.blue800;
      case 'cancelled':
        return PdfColors.red800;
      default:
        return PdfColors.grey800;
    }
  }
}
