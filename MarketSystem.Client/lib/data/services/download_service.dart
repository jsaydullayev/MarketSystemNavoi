import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:open_filex/open_filex.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/utils/file_helper.dart';
import 'http_service.dart';

class DownloadService {
  static DownloadService? _instance;
  final HttpService _httpService;

  DownloadService._internal(this._httpService);

  static DownloadService getInstance(HttpService httpService) {
    // Lazy singleton — the `??` returns the existing instance if any,
    // otherwise the assignment expression produces (and stores) a new
    // one. Whichever branch wins, the result is non-null.
    return _instance ?? (_instance = DownloadService._internal(httpService));
  }

  /// DateTime ni yyyy-MM-dd formatida query parametr uchun formatlash
  String _formatDateForQuery(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Kategoriyalarni Excel formatida yuklab olish
  Future<void> downloadCategories({String lang = 'uz'}) async {
    final response = await _httpService.get(
      '${ApiConstants.productCategoriesExportExcel}?lang=$lang',
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Kategoriyalarni yuklab olishda xatolik',
      );
    }
    final filename = lang == 'ru'
        ? 'Kategorii_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : 'Kategoriyalar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveDownloadedFile(response.bodyBytes, filename);
  }

  /// Mahsulotlarni Excel formatida yuklab olish
  Future<void> downloadProducts() async {
    final response = await _httpService.get(ApiConstants.productsExportExcel);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Mahsulotlarni yuklab olishda xatolik',
      );
    }
    final filename =
        'mahsulotlar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveDownloadedFile(response.bodyBytes, filename);
  }

  /// Umumiy hisobotni Excel formatida yuklab olish
  Future<void> downloadComprehensiveReport({
    DateTime? date,
    String lang = 'uz',
  }) async {
    final params = <String, String>{'lang': lang};
    if (date != null) params['date'] = _formatDateForQuery(date);
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = '/Reports/comprehensive-report/export?$query';

    final response = await _httpService.get(url);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Hisobotlarni yuklab olishda xatolik',
      );
    }
    final filename = lang == 'ru'
        ? 'otchet_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : 'hisobot_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveDownloadedFile(response.bodyBytes, filename);
  }

  /// Ombordagi (sklad) mahsulotlarni Excel formatida yuklab olish.
  /// Reports → Ombor tabidagi yuklab olish tugmasi shu metodni chaqiradi:
  /// joriy ombor holati (barcha mahsulotlar, qoldiq, narxlar, qiymatlar).
  /// Backend RBAC: tannarx/foyda ustunlari faqat Owner/Admin uchun chiqadi.
  Future<void> downloadInventoryReport({
    DateTime? date,
    String lang = 'uz',
  }) async {
    final params = <String, String>{'lang': lang};
    if (date != null) params['date'] = _formatDateForQuery(date);
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = '/Reports/inventory-report/export?$query';

    final response = await _httpService.get(url);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Ombor hisobotini yuklab olishda xatolik',
      );
    }
    final filename = lang == 'ru'
        ? 'sklad_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : 'ombor_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveDownloadedFile(response.bodyBytes, filename);
  }

  /// Mijozlarni Excel formatida yuklab olish.
  /// Backend endpoint: GET /api/Customers/ExportCustomersToExcel/export
  /// (added 2026-05-18 — mirrors /api/Products/.../export so the same
  /// download flow handles both files).
  Future<void> downloadCustomers({String lang = 'uz'}) async {
    final response = await _httpService.get(
      '/Customers/ExportCustomersToExcel/export?lang=$lang',
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Mijozlarni yuklab olishda xatolik',
      );
    }
    final filename = 'mijozlar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveDownloadedFile(response.bodyBytes, filename);
  }

  /// ApiException-2 — single dispatch for "save these bytes". Web hits the
  /// browser's blob download path; mobile/desktop drops the file into the
  /// Downloads folder and asks the OS to open it. Errors from either branch
  /// surface as `ApiException(statusCode: 0)` so callers can branch on
  /// `e is ApiException` instead of double-catching.
  Future<void> _saveDownloadedFile(List<int> bytes, String filename) async {
    if (kIsWeb) {
      _downloadWeb(bytes, filename);
    } else {
      await _downloadMobileDesktop(bytes, filename);
    }
  }

  /// Faylni mobile/desktop device ga yuklab olish.
  /// ApiException-2 — disk / open errors fold into ApiException(statusCode: 0)
  /// so the snackbar at the call site can render a localized message instead
  /// of "Exception: Exception: Faylni yuklab olishda xatolik: ...".
  Future<void> _downloadMobileDesktop(List<int> bytes, String filename) async {
    try {
      // FileHelper bilan bir xil, platformaga mos va yozish mumkin bo'lgan
      // papka. Ilgari bu yerda getDownloadsDirectory() chaqirilardi — iOS
      // sandbox'ida Downloads papkasi YO'Q, u null qaytaradi, natijada
      // Hisobotlar bo'limidagi HAR BIR eksport iPhone'da xatolik berardi.
      // Android'da esa u ilovaning ichki papkasiga tushib, foydalanuvchi
      // faylni topa olmasdi.
      final directory = await FileHelper.resolveSaveDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      // OS automatic ravishda default app (Excel, LibreOffice, etc) bilan ochadi.
      await OpenFilex.open(filePath);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Faylni yuklab olishda xatolik: $e',
      );
    }
  }

  /// Faylni web browser orqali yuklab olish (Browser Download API).
  void _downloadWeb(List<int> bytes, String filename) {
    try {
      final blob = html.Blob([
        bytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      // Memory leak oldini olish uchun blob URL'ni tozalash.
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Web download xatolik: $e',
      );
    }
  }

  /// Faylni web browser orqali PDF formatda yuklab olish.
  void _downloadWebPdf(List<int> bytes, String filename) {
    try {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Web PDF download xatolik: $e',
      );
    }
  }

  /// Kunlik hisobotni PDF formatida yuklab olish
  Future<void> downloadDailyReportToPdf(
    DateTime date, {
    String lang = 'uz',
  }) async {
    final response = await _httpService.get(
      '/Reports/daily/export-pdf?date=${_formatDateForQuery(date)}&lang=$lang',
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Kunlik hisobotni PDF formatida yuklab olishda xatolik',
      );
    }
    final filename =
        'daily_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdf(response.bodyBytes, filename);
  }

  /// Davr hisobotni PDF formatida yuklab olish
  Future<void> downloadPeriodReportToPdf(
    DateTime start,
    DateTime end, {
    String lang = 'uz',
  }) async {
    final response = await _httpService.get(
      '/Reports/period/export-pdf?start=${_formatDateForQuery(start)}&end=${_formatDateForQuery(end)}&lang=$lang',
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage:
            'Davriy hisobotni PDF formatida yuklab olishda xatolik',
      );
    }
    final filename =
        'period_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdf(response.bodyBytes, filename);
  }

  /// Umumiy hisobotni PDF formatida yuklab olish
  Future<void> downloadComprehensiveReportToPdf(
    DateTime date, {
    String lang = 'uz',
  }) async {
    final response = await _httpService.get(
      '/Reports/comprehensive/export-pdf?date=${_formatDateForQuery(date)}&lang=$lang',
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage:
            'Umumiy hisobotni PDF formatida yuklab olishda xatolik',
      );
    }
    final filename =
        'comprehensive_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdf(response.bodyBytes, filename);
  }

  /// PDF-variant of [_saveDownloadedFile]. Web uses the PDF MIME-type blob
  /// path so the browser opens an inline preview instead of forcing a
  /// download as `application/octet-stream`.
  Future<void> _savePdf(List<int> bytes, String filename) async {
    if (kIsWeb) {
      _downloadWebPdf(bytes, filename);
    } else {
      await _downloadMobileDesktop(bytes, filename);
    }
  }
}
