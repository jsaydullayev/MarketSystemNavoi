using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

// ProductCategory DTOs
public record ProductCategoryDto(
    [property: JsonPropertyName("id")] int Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("icon")] string? Icon,  // Emoji glyph chosen in the UI
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("productCount")] int ProductCount  // ✅ Number of products in this category
);

public record CreateProductCategoryRequest(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("icon")] string? Icon
);

public record UpdateProductCategoryRequest(
    [property: JsonPropertyName("id")] int Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("icon")] string? Icon,
    [property: JsonPropertyName("isActive")] bool IsActive
);
