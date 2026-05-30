import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/http_service.dart';
import '../models/import_models.dart';

// Excel ustunlari (0-indexed):
// A=0 Tovar nomi | B=1 Sotuv narxi | C=2 Minimal narx
// D=3 Kategoriya | E=4 Birlik      | F=5 Minimal chegara

class ProductImportService {
  final AuthProvider authProvider;
  late final HttpService _http;

  ProductImportService({required this.authProvider}) {
    _http = HttpService();
  }

  // ── Fayl tanlash va parse qilish ───────────────────────────────────────

  Future<List<ImportProductRow>?> pickAndParseExcel() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
        allowMultiple: false,
      );
    } catch (e) {
      debugPrint('FilePicker xato: $e');
      return null;
    }

    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    // Parsing a large .xlsx is CPU-bound (Excel.decodeBytes + a full row
    // walk) and was running on the UI isolate — it froze the screen for
    // seconds on big files while the spinner sat still. Offload it to a
    // background isolate via compute().
    return compute(_parseExcelRows, bytes);
  }

  // ── Template Excel generatsiya ─────────────────────────────────────────

  static Uint8List generateTemplate({String lang = 'uz'}) {
    final isRu = lang == 'ru';

    // excel v3.0.0 + archive 3.6.x: rename() calls delete() which calls
    // _archive.files.removeWhere() — unmodifiable list exception.
    // Fix: skip rename, write directly to the default 'Sheet1'.
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = isRu
        ? [
            'Название*',
            'Цена продажи*',
            'Мин. цена',
            'Категория',
            'Ед. изм. (шт/кг/м)',
            'Мин. остаток',
          ]
        : [
            'Tovar nomi*',
            'Sotuv narxi*',
            'Minimal narx',
            'Kategoriya',
            'Birlik (dona/kg/m)',
            'Minimal chegara',
          ];

    final sample = isRu
        ? ['Яблоко', '5000', '4500', 'Фрукты', 'кг', '10']
        : ['Olma', '5000', '4500', 'Mevalar', 'kg', '10'];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        backgroundColorHex: 'FFFF6B00',
        fontColorHex: 'FFFFFFFF',
        bold: true,
      );
    }

    for (var i = 0; i < sample.length; i++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
              .value =
          sample[i];
    }

    sheet.setColumnWidth(0, 30);
    for (var i = 1; i < 6; i++) {
      sheet.setColumnWidth(i, 18);
    }

    final encoded = excel.encode();
    return encoded != null ? Uint8List.fromList(encoded) : Uint8List(0);
  }

  // ── API chaqiruvlari ───────────────────────────────────────────────────

  Future<ImportPreviewResult> preview(List<ImportProductRow> rows) async {
    final response = await _http.post(
      ApiConstants.productsImportPreview,
      body: rows.map((r) => r.toJson()).toList(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ImportPreviewResult.fromJson(data);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Preview yuklanmadi',
    );
  }

  Future<ImportResult> confirm(ImportConfirmRequest request) async {
    final response = await _http.post(
      ApiConstants.productsImportConfirm,
      body: request.toJson(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ImportResult.fromJson(data);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Import amalga oshmadi',
    );
  }
}

// ── Isolate-side Excel parsing ────────────────────────────────────────────
// Top-level (not a method) so it can be handed to compute(). Takes the raw
// file bytes and returns the parsed rows; both ends are isolate-sendable.

List<ImportProductRow>? _parseExcelRows(Uint8List bytes) {
  try {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.firstOrNull;
    if (sheet == null || sheet.rows.isEmpty) return [];

    final rows = <ImportProductRow>[];

    // 0-qator — sarlavhalar, 1-qatordan boshlab ma'lumotlar
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      final name = _cellString(row, 0)?.trim();
      final salePrice = _cellDouble(row, 1);
      final minSalePrice = _cellDouble(row, 2);
      final categoryName = _cellString(row, 3)?.trim();
      final unitName = _cellString(row, 4)?.trim();
      final minThreshold = _cellDouble(row, 5);

      // To'liq bo'sh qatorlarni o'tkazib yuboramiz
      if ((name == null || name.isEmpty) && salePrice == null) continue;

      rows.add(
        ImportProductRow(
          rowNumber: i + 1,
          name: name?.isEmpty == true ? null : name,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          categoryName: categoryName?.isEmpty == true ? null : categoryName,
          unitName: unitName?.isEmpty == true ? null : unitName,
          minThreshold: minThreshold,
        ),
      );
    }
    return rows;
  } catch (e) {
    debugPrint('Excel parse xato: $e');
    return null;
  }
}

// excel v3: cell.value dynamic (String, int, double, bool, null)
String? _cellString(List<Data?> row, int col) {
  if (col >= row.length) return null;
  final v = row[col]?.value;
  if (v == null) return null;
  return v.toString();
}

double? _cellDouble(List<Data?> row, int col) {
  if (col >= row.length) return null;
  final v = row[col]?.value;
  if (v == null) return null;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse(v.toString());
}
