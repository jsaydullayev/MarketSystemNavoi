using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

// ── Input ──────────────────────────────────────────────────────────────────

/// Excel dan bir qator ma'lumot (Flutter tomonidan JSON sifatida yuboriladi).
public record ImportProductRowDto(
    [property: JsonPropertyName("rowNumber")] int RowNumber,
    [property: JsonPropertyName("name")] string? Name,
    [property: JsonPropertyName("salePrice")] decimal? SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal? MinSalePrice,
    [property: JsonPropertyName("categoryName")] string? CategoryName,
    [property: JsonPropertyName("unitName")] string? UnitName,
    [property: JsonPropertyName("minThreshold")] decimal? MinThreshold
);

/// Confirm so'rovida foydalanuvchi kategoriya moslamalarini yuboradi.
/// Key = excelda yozilgan kategoriya nomi, Value = tanlangan CategoryId
/// (null bo'lsa — yangi kategoriya yaratiladi).
public record ImportConfirmDto(
    [property: JsonPropertyName("rows")] List<ImportProductRowDto> Rows,
    [property: JsonPropertyName("categoryOverrides")]
    Dictionary<string, int?> CategoryOverrides
);

// ── Preview result ─────────────────────────────────────────────────────────

public enum ImportRowStatus { Valid, Warning, Error }

/// Bir qatorning tahlil natijasi.
public record ImportRowResultDto(
    [property: JsonPropertyName("rowNumber")] int RowNumber,
    [property: JsonPropertyName("inputName")] string? InputName,
    [property: JsonPropertyName("status")] ImportRowStatus Status,
    [property: JsonPropertyName("errors")] List<string> Errors,
    [property: JsonPropertyName("warnings")] List<string> Warnings,
    // Saqlaniladigan qiymatlar
    [property: JsonPropertyName("resolvedName")] string? ResolvedName,
    [property: JsonPropertyName("resolvedSalePrice")] decimal? ResolvedSalePrice,
    [property: JsonPropertyName("resolvedMinSalePrice")] decimal? ResolvedMinSalePrice,
    [property: JsonPropertyName("resolvedCategoryId")] int? ResolvedCategoryId,
    [property: JsonPropertyName("resolvedCategoryName")] string? ResolvedCategoryName,
    [property: JsonPropertyName("suggestedCategoryName")] string? SuggestedCategoryName,
    [property: JsonPropertyName("resolvedUnit")] int ResolvedUnit,
    [property: JsonPropertyName("resolvedUnitName")] string ResolvedUnitName,
    [property: JsonPropertyName("resolvedMinThreshold")] decimal ResolvedMinThreshold,
    [property: JsonPropertyName("isNewCategory")] bool IsNewCategory
);

/// Preview (dry-run) natijasi — bazaga hech narsa yozilmaydi.
public record ImportPreviewResultDto(
    [property: JsonPropertyName("rows")] List<ImportRowResultDto> Rows,
    [property: JsonPropertyName("validCount")] int ValidCount,
    [property: JsonPropertyName("warningCount")] int WarningCount,
    [property: JsonPropertyName("errorCount")] int ErrorCount,
    [property: JsonPropertyName("newCategories")] List<string> NewCategories
);

// ── Confirm result ─────────────────────────────────────────────────────────

/// Haqiqiy import natijasi.
public record ImportResultDto(
    [property: JsonPropertyName("importedCount")] int ImportedCount,
    [property: JsonPropertyName("skippedCount")] int SkippedCount,
    [property: JsonPropertyName("newCategoriesCreated")] int NewCategoriesCreated,
    [property: JsonPropertyName("skippedNames")] List<string> SkippedNames
);
