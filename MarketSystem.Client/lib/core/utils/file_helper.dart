import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

/// Fayllarni platformaga mos saqlash uchun yordamchi klass
/// Web, Mobile va Desktop uchun alohida mexanizmlar ishlaydi
class FileHelper {
  /// Excel faylini saqlaydi va ochadi
  /// Web'da - browser download orqali
  /// Mobile/Desktop - path_provider orqali
  static Future<bool> saveAndOpenExcel(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Web muhiti - browser download orqali
        return _downloadWeb(
          bytes,
          fileName,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        // Mobile/Desktop muhiti - fayl tizimiga yozish
        return await _saveMobileDesktop(bytes, fileName);
      }
    } catch (e) {
      debugPrint('Error saving or opening excel file: $e');
      return false;
    }
  }

  /// PDF faylini saqlaydi va ochadi
  /// Web'da - browser download orqali
  /// Mobile/Desktop - path_provider orqali
  static Future<bool> saveAndOpenPdf(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Web muhiti - browser download orqali
        return _downloadWeb(bytes, fileName, 'application/pdf');
      } else {
        // Mobile/Desktop muhiti - fayl tizimiga yozish
        return await _saveMobileDesktop(bytes, fileName);
      }
    } catch (e) {
      debugPrint('Error saving or opening pdf file: $e');
      return false;
    }
  }

  /// Web muhiti uchun download (Browser API)
  static bool _downloadWeb(List<int> bytes, String fileName, String mimeType) {
    try {
      // Blob yaratish
      final blob = html.Blob([bytes], mimeType);

      // Download URL yaratish
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Anchor element yaratish va click qilish
      final anchor = html.AnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';

      // DOM ga qo'shish, click qilish, va o'chirish
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // URLni tozalash (memory leak oldini olish uchun)
      html.Url.revokeObjectUrl(url);

      debugPrint('Web download started: $fileName');
      return true;
    } catch (e) {
      debugPrint('Web download error: $e');
      return false;
    }
  }

  /// Mobile/Desktop muhiti uchun faylni saqlash va ochish
  static Future<bool> _saveMobileDesktop(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final path = await _getFilePath(fileName);
      if (path == null) return false;

      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // Faylni ochish - OS automatic ravishda default app bilan ochadi
      final result = await OpenFilex.open(path);

      debugPrint('File saved: $path, Open result: ${result.type}');
      return true;
    } catch (e) {
      debugPrint('Error saving file on mobile/desktop: $e');
      return false;
    }
  }

  /// Faylni saqlash uchun platformaga mos, YOZISH MUMKIN bo'lgan papka.
  /// DownloadService ham shu yagona manbadan foydalanadi.
  ///
  /// Android: ilgari `/storage/emulated/0/Download` ishlatilardi. Bu papka
  /// qurilmada MAVJUD, shuning uchun `exists()` doim true qaytarib, quyidagi
  /// fallback hech qachon ishga tushmasdi — `writeAsBytes` esa Android 10+ da
  /// scoped storage sababli "Permission denied (errno 13)" bilan yiqilardi
  /// (WRITE_EXTERNAL_STORAGE manifestda maxSdkVersion=28 bilan cheklangan, ya'ni
  /// zamonaviy Android'da umuman berilmaydi). Endi ilovaning o'z tashqi
  /// papkasiga yozamiz: hech qanday ruxsat talab qilinmaydi va OpenFilex uni
  /// FileProvider orqali tizim ilovasida ocha oladi (u yerdan ulashish/saqlash
  /// mumkin).
  ///
  /// iOS: sandbox'da Downloads papkasi YO'Q — hujjatlar papkasi ishlatiladi.
  static Future<Directory> resolveSaveDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Desktop (Windows/macOS/Linux) — Downloads.
      directory = await getDownloadsDirectory();
    }

    directory ??= await getApplicationDocumentsDirectory();

    // path_provider papkaning mavjudligini KAFOLATLAMAYDI — yozishdan oldin
    // yaratamiz, aks holda writeAsBytes ENOENT beradi.
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Platformaga mos fayl yo'lini olish
  /// Web'da null qaytaradi (chunki fayl tizimi yo'q)
  static Future<String?> _getFilePath(String fileName) async {
    // Web'da fayl tizimi yo'q, shuning uchun null qaytaramiz
    if (kIsWeb) return null;

    try {
      final directory = await resolveSaveDirectory();

      // Fayl nomi takrorlanmasligi uchun
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nameWithoutExtension = fileName.split('.').first;
      final extension = fileName.split('.').last;

      return '${directory.path}/${nameWithoutExtension}_$timestamp.$extension';
    } catch (e) {
      debugPrint('Error getting directory: $e');
      // Oxirgi chora sifatida vaqtinchalik papkaga saqlash
      try {
        final tempDir = await getTemporaryDirectory();
        return '${tempDir.path}/$fileName';
      } catch (e2) {
        debugPrint('Error getting temp directory: $e2');
        return null;
      }
    }
  }
}
