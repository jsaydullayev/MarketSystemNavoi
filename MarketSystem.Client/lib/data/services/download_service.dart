import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class DownloadService {
  /// Kategoriyalarni Excel/CSV formatida yuklab olish
  Future<void> downloadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/ProductCategories/ExportCategoriesToExcel'),
        headers: {
          'Content-Type': 'application/csv',
        },
      );

      if (response.statusCode == 200) {
        _downloadFile(
          response.bodyBytes,
          'kategoriyalar_${DateTime.now().millisecondsSinceEpoch}.csv',
          'text/csv',
        );
      } else {
        throw Exception('Kategoriyalarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategoriyalarni yuklab olishda xatolik: $e');
    }
  }

  /// Mahsulotlarni Excel/CSV formatida yuklab olish
  Future<void> downloadProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Products/ExportProductsToExcel'),
        headers: {
          'Content-Type': 'application/csv',
        },
      );

      if (response.statusCode == 200) {
        _downloadFile(
          response.bodyBytes,
          'mahsulotlar_${DateTime.now().millisecondsSinceEpoch}.csv',
          'text/csv',
        );
      } else {
        throw Exception('Mahsulotlarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mahsulotlarni yuklab olishda xatolik: $e');
    }
  }

  /// Sotuvlarni Excel/CSV formatida yuklab olish
  Future<void> downloadSales() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Sales/ExportSalesToExcel'),
        headers: {
          'Content-Type': 'application/csv',
        },
      );

      if (response.statusCode == 200) {
        _downloadFile(
          response.bodyBytes,
          'sotuvlar_${DateTime.now().millisecondsSinceEpoch}.csv',
          'text/csv',
        );
      } else {
        throw Exception('Sotuvlarni yuklab olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sotuvlarni yuklab olishda xatolik: $e');
    }
  }

  /// Faylni browser orqali yuklab olish
  void _downloadFile(List<int> bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
