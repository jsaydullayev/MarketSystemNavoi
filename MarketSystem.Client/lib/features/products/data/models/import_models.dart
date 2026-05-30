// Backend ImportDTOs.cs bilan mos keladigan Flutter modellari.

// ── Input ──────────────────────────────────────────────────────────────────

class ImportProductRow {
  final int rowNumber;
  final String? name;
  final double? salePrice;
  final double? minSalePrice;
  final String? categoryName;
  final String? unitName;
  final double? minThreshold;

  const ImportProductRow({
    required this.rowNumber,
    this.name,
    this.salePrice,
    this.minSalePrice,
    this.categoryName,
    this.unitName,
    this.minThreshold,
  });

  Map<String, dynamic> toJson() => {
    'rowNumber': rowNumber,
    if (name != null) 'name': name,
    if (salePrice != null) 'salePrice': salePrice,
    if (minSalePrice != null) 'minSalePrice': minSalePrice,
    if (categoryName != null) 'categoryName': categoryName,
    if (unitName != null) 'unitName': unitName,
    if (minThreshold != null) 'minThreshold': minThreshold,
  };
}

class ImportConfirmRequest {
  final List<ImportProductRow> rows;
  final Map<String, int?> categoryOverrides;

  const ImportConfirmRequest({
    required this.rows,
    this.categoryOverrides = const {},
  });

  Map<String, dynamic> toJson() => {
    'rows': rows.map((r) => r.toJson()).toList(),
    'categoryOverrides': categoryOverrides,
  };
}

// ── Preview result ─────────────────────────────────────────────────────────

enum ImportRowStatus { valid, warning, error }

class ImportRowResult {
  final int rowNumber;
  final String? inputName;
  final ImportRowStatus status;
  final List<String> errors;
  final List<String> warnings;
  final String? resolvedName;
  final double? resolvedSalePrice;
  final double? resolvedMinSalePrice;
  final int? resolvedCategoryId;
  final String? resolvedCategoryName;
  final String? suggestedCategoryName;
  final int resolvedUnit;
  final String resolvedUnitName;
  final double resolvedMinThreshold;
  final bool isNewCategory;

  const ImportRowResult({
    required this.rowNumber,
    this.inputName,
    required this.status,
    required this.errors,
    required this.warnings,
    this.resolvedName,
    this.resolvedSalePrice,
    this.resolvedMinSalePrice,
    this.resolvedCategoryId,
    this.resolvedCategoryName,
    this.suggestedCategoryName,
    required this.resolvedUnit,
    required this.resolvedUnitName,
    required this.resolvedMinThreshold,
    required this.isNewCategory,
  });

  factory ImportRowResult.fromJson(Map<String, dynamic> j) => ImportRowResult(
    rowNumber: j['rowNumber'] as int,
    inputName: j['inputName'] as String?,
    status: _parseStatus(j['status']),
    errors: List<String>.from(j['errors'] as List),
    warnings: List<String>.from(j['warnings'] as List),
    resolvedName: j['resolvedName'] as String?,
    resolvedSalePrice: (j['resolvedSalePrice'] as num?)?.toDouble(),
    resolvedMinSalePrice: (j['resolvedMinSalePrice'] as num?)?.toDouble(),
    resolvedCategoryId: j['resolvedCategoryId'] as int?,
    resolvedCategoryName: j['resolvedCategoryName'] as String?,
    suggestedCategoryName: j['suggestedCategoryName'] as String?,
    resolvedUnit: (j['resolvedUnit'] as num).toInt(),
    resolvedUnitName: j['resolvedUnitName'] as String? ?? 'dona',
    resolvedMinThreshold: (j['resolvedMinThreshold'] as num?)?.toDouble() ?? 5.0,
    isNewCategory: j['isNewCategory'] as bool? ?? false,
  );

  static ImportRowStatus _parseStatus(dynamic v) {
    switch (v) {
      case 0:
      case 'Valid':
        return ImportRowStatus.valid;
      case 1:
      case 'Warning':
        return ImportRowStatus.warning;
      default:
        return ImportRowStatus.error;
    }
  }
}

class ImportPreviewResult {
  final List<ImportRowResult> rows;
  final int validCount;
  final int warningCount;
  final int errorCount;
  final List<String> newCategories;

  const ImportPreviewResult({
    required this.rows,
    required this.validCount,
    required this.warningCount,
    required this.errorCount,
    required this.newCategories,
  });

  factory ImportPreviewResult.fromJson(Map<String, dynamic> j) =>
      ImportPreviewResult(
        rows: (j['rows'] as List)
            .map((r) => ImportRowResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        validCount: j['validCount'] as int,
        warningCount: j['warningCount'] as int,
        errorCount: j['errorCount'] as int,
        newCategories: List<String>.from(j['newCategories'] as List),
      );

  bool get hasImportable => validCount + warningCount > 0;
}

// ── Confirm result ─────────────────────────────────────────────────────────

class ImportResult {
  final int importedCount;
  final int skippedCount;
  final int newCategoriesCreated;
  final List<String> skippedNames;

  const ImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.newCategoriesCreated,
    required this.skippedNames,
  });

  factory ImportResult.fromJson(Map<String, dynamic> j) => ImportResult(
    importedCount: j['importedCount'] as int,
    skippedCount: j['skippedCount'] as int,
    newCategoriesCreated: j['newCategoriesCreated'] as int,
    skippedNames: List<String>.from(j['skippedNames'] as List),
  );
}
