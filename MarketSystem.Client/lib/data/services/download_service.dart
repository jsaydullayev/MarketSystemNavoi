import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:open_filex/open_filex.dart';
import 'http_service.dart';

class DownloadService {
  static DownloadService? _instance;
  final HttpService _httpService;

  DownloadService._internal(this._httpService);

  static DownloadService getInstance(HttpService httpService) {
    _instance ??= DownloadService._internal(httpService);
    return _instance!;
  }

  /// Kategoriyalarni Excel formatida yuklab olish
  Future<void> downloadCategories() async {
    try {
      final response =
          await _httpService.get('/Reports/ExportCategoriesToExcel');

      if (response.statusCode == 200) {
        final filename =
            'kategoriyalar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        if (kIsWeb) {
          _downloadWeb(response.bodyBytes, filename);
        } else {
          await _downloadMobileDesktop(response.bodyBytes, filename);
        }
      } else {
        throw Exception(
            'Kategoriyalarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategoriyalarni yuklab olishda xatolik: $e');
    }
  }

  /// Mahsulotlarni Excel formatida yuklab olish
  Future<void> downloadProducts() async {
    try {
      final response =
          await _httpService.get('/Products/ExportProductsToExcel');

      if (response.statusCode == 200) {
        final filename =
            'mahsulotlar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        if (kIsWeb) {
          _downloadWeb(response.bodyBytes, filename);
        } else {
          await _downloadMobileDesktop(response.bodyBytes, filename);
        }
      } else {
        throw Exception(
            'Mahsulotlarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mahsulotlarni yuklab olishda xatolik: $e');
    }
  }

  /// Sotuvlarni Excel formatida yuklab olish
  Future<void> downloadSales({DateTime? startDate, DateTime? endDate}) async {
    try {
      String url = '/Reports/ExportSalesToExcel';

      // Qo'shimcha parametrlarni qo'shish
      if (startDate != null || endDate != null) {
        url += '?';
        if (startDate != null) {
          url += 'startDate=${startDate.toIso8601String()}';
          if (endDate != null) url += '&';
        }
        if (endDate != null) {
          url += 'endDate=${endDate.toIso8601String()}';
        }
      }

      final response = await _httpService.get(url);

      if (response.statusCode == 200) {
        final filename =
            'sotuvlar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        if (kIsWeb) {
          _downloadWeb(response.bodyBytes, filename);
        } else {
          await _downloadMobileDesktop(response.bodyBytes, filename);
        }
      } else {
        throw Exception(
            'Sotuvlarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sotuvlarni yuklab olishda xatolik: $e');
    }
  }

  /// Umumiy hisobotni Excel formatida yuklab olish
  Future<void> downloadComprehensiveReport({DateTime? date}) async {
    try {
      String url = '/Reports/ExportComprehensiveReportToExcel';

      // Sana parametrini qo'shish
      if (date != null) {
        url += '?date=${date.toIso8601String()}';
      }

      final response = await _httpService.get(url);

      if (response.statusCode == 200) {
        final filename =
            'hisobotlar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        if (kIsWeb) {
          _downloadWeb(response.bodyBytes, filename);
        } else {
          await _downloadMobileDesktop(response.bodyBytes, filename);
        }
      } else {
        throw Exception(
            'Hisobotlarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hisobotlarni yuklab olishda xatolik: $e');
    }
  }

  /// Mijozlarni Excel formatida yuklab olish
  Future<void> downloadCustomers() async {
    try {
      final response =
          await _httpService.get('/Reports/ExportCustomersToExcel');

      if (response.statusCode == 200) {
        final filename =
            'mijozlar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        if (kIsWeb) {
          _downloadWeb(response.bodyBytes, filename);
        } else {
          await _downloadMobileDesktop(response.bodyBytes, filename);
        }
      } else {
        throw Exception(
            'Mijozlarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mijozlarni yuklab olishda xatolik: $e');
    }
  }

  /// Faylni mobile/desktop device ga yuklab olish
  Future<void> _downloadMobileDesktop(List<int> bytes, String filename) async {
    try {
      // Downloads papkasini olish
      final directory = await getDownloadsDirectory();

      if (directory != null) {
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);

        // Faylni yozish
        await file.writeAsBytes(bytes);

        // Faylni ochish - OS automatic ravishda default app (Excel, LibreOffice, etc) bilan ochadi
        await OpenFilex.open(filePath);
      } else {
        throw Exception('Downloads papkasini topib bo\'lmadi');
      }
    } catch (e) {
      throw Exception('Faylni yuklab olishda xatolik: $e');
    }
  }

  /// Faylni web browser orqali yuklab olish (Browser Download API)
  void _downloadWeb(List<int> bytes, String filename) {
    try {
      // Blob yaratish
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      // Download URL yaratish
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Anchor element yaratish va click qilish
      final anchor = html.AnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';

      // DOM ga qo'shish, click qilish, va o'chirish
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // URLni tozalash (memory leak oldini olish uchun)
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Web download xatolik: $e');
    }
  }
}
