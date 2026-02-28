import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<String?> saveAndOpenExcel(List<int> bytes, String fileName) async {
    try {
      final path = await _getFilePath(fileName);
      if (path == null) return null;

      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      
      // Try to open the file automatically
      await OpenFilex.open(path);
      
      return path;
    } catch (e) {
      debugPrint('Error saving or opening excel file: $e');
      return null;
    }
  }

  static Future<String?> _getFilePath(String fileName) async {
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        // Android da Downloads papkasiga saqlaymiz, topolmasa External Storage
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS da faqat application documents papkasiga ruxsat bor
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Kompyuter uchun Downloads
        directory = await getDownloadsDirectory();
      }

      if (directory != null) {
        // Fayl nomi takrorlanmasligi uchun
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExtension = fileName.split('.').first;
        final extension = fileName.split('.').last;
        
        return '${directory.path}/${nameWithoutExtension}_$timestamp.$extension';
      }
    } catch (e) {
      debugPrint('Error getting directory: $e');
      // Oxirgi chora sifatida vaqtinchalik papkaga saqlash
      directory = await getTemporaryDirectory();
      return '${directory.path}/$fileName';
    }
    
    return null;
  }
}
