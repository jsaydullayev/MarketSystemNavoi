using MarketSystem.Domain.Enums;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

/// <summary>
/// Yangi product yaratish requesti (Unit bilan birga)
/// </summary>
public record CreateProductRequest(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("minThreshold")] decimal MinThreshold,
    [property: JsonPropertyName("unit")] int Unit,  // UnitType enum as int
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary = false
);

/// <summary>
/// Product yangilash requesti
/// </summary>
public record UpdateProductRequest(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("minThreshold")] decimal MinThreshold,
    [property: JsonPropertyName("unit")] int Unit,  // UnitType enum as int
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary
);

/// <summary>
/// Product response DTO (Unit bilan birga)
/// </summary>
public record ProductDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("minThreshold")] decimal MinThreshold,
    [property: JsonPropertyName("unit")] int Unit,  // UnitType enum as int
    [property: JsonPropertyName("unitName")] string UnitName,  // "dona", "kg", "m"
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("categoryName")] string? CategoryName,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary,
    [property: JsonPropertyName("isInStock")] bool IsInStock,
    [property: JsonPropertyName("isLowStock")] bool IsLowStock
);

/// <summary>
/// Zakup (purchase) yaratish requesti
/// </summary>
public record CreateZakupRequest(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice
);



