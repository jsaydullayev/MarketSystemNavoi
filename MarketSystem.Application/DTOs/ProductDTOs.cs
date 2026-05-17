using System.ComponentModel.DataAnnotations;
using MarketSystem.Domain.Enums;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record CreateProductRequest(
    [property: JsonPropertyName("name")]
    [property: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [property: StringLength(200, MinimumLength = 1, ErrorMessage = "Nom 1-200 belgi bo'lishi kerak")]
    string Name,

    [property: JsonPropertyName("costPrice")]
    [property: Range(0, double.MaxValue, ErrorMessage = "Tannarx 0 dan katta bo'lishi kerak")]
    decimal CostPrice,

    [property: JsonPropertyName("salePrice")]
    [property: Range(0, double.MaxValue, ErrorMessage = "Sotuv narxi 0 dan katta bo'lishi kerak")]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [property: Range(0, double.MaxValue, ErrorMessage = "Minimal narx 0 dan katta bo'lishi kerak")]
    decimal MinSalePrice,

    [property: JsonPropertyName("quantity")]
    [property: Range(0, double.MaxValue, ErrorMessage = "Miqdor manfiy bo'lishi mumkin emas")]
    decimal Quantity,

    [property: JsonPropertyName("minThreshold")]
    [property: Range(0, double.MaxValue, ErrorMessage = "Minimal chegara 0 dan katta bo'lishi kerak")]
    decimal MinThreshold,

    [property: JsonPropertyName("unit")] int Unit,
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary = false
);

public record UpdateProductRequest(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("name")]
    [property: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [property: StringLength(200, MinimumLength = 1)]
    string Name,

    [property: JsonPropertyName("costPrice")]
    [property: Range(0, double.MaxValue)]
    decimal CostPrice,

    [property: JsonPropertyName("salePrice")]
    [property: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [property: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("quantity")]
    [property: Range(0, double.MaxValue)]
    decimal Quantity,

    [property: JsonPropertyName("minThreshold")]
    [property: Range(0, double.MaxValue)]
    decimal MinThreshold,

    [property: JsonPropertyName("unit")] int Unit,
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary
);

public record ProductDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("minThreshold")] decimal MinThreshold,
    [property: JsonPropertyName("unit")] int Unit,
    [property: JsonPropertyName("unitName")] string UnitName,
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("categoryName")] string? CategoryName,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary,
    [property: JsonPropertyName("isInStock")] bool IsInStock,
    [property: JsonPropertyName("isLowStock")] bool IsLowStock
);

public record CreateZakupRequest(
    [property: JsonPropertyName("productId")]
    [property: Required]
    Guid ProductId,

    [property: JsonPropertyName("quantity")]
    [property: Range(0.001, double.MaxValue, ErrorMessage = "Miqdor 0 dan katta bo'lishi kerak")]
    decimal Quantity,

    [property: JsonPropertyName("costPrice")]
    [property: Range(0, double.MaxValue, ErrorMessage = "Narx manfiy bo'lishi mumkin emas")]
    decimal CostPrice
);

public record CreateProductDto(
    [property: JsonPropertyName("name")]
    [property: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [property: StringLength(200, MinimumLength = 1)]
    string Name,

    [property: JsonPropertyName("isTemporary")] bool IsTemporary,

    [property: JsonPropertyName("salePrice")]
    [property: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [property: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("minThreshold")]
    [property: Range(0, double.MaxValue)]
    decimal MinThreshold,

    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("unit")] int Unit = 1
);

public record UpdateProductDto(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("name")]
    [property: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [property: StringLength(200, MinimumLength = 1)]
    string Name,

    [property: JsonPropertyName("salePrice")]
    [property: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [property: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("minThreshold")]
    [property: Range(0, double.MaxValue)]
    decimal MinThreshold,

    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("unit")] int Unit = 1,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary = false
);
