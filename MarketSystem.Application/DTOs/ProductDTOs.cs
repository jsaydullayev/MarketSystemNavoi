using System.ComponentModel.DataAnnotations;
using MarketSystem.Domain.Enums;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record CreateProductRequest(
    [property: JsonPropertyName("name")]
    [param: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [param: StringLength(200, MinimumLength = 1, ErrorMessage = "Nom 1-200 belgi bo'lishi kerak")]
    string Name,

    [property: JsonPropertyName("costPrice")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Tannarx 0 dan katta bo'lishi kerak")]
    decimal CostPrice,

    [property: JsonPropertyName("salePrice")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Sotuv narxi 0 dan katta bo'lishi kerak")]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Minimal narx 0 dan katta bo'lishi kerak")]
    decimal MinSalePrice,

    [property: JsonPropertyName("quantity")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Miqdor manfiy bo'lishi mumkin emas")]
    decimal Quantity,

    [property: JsonPropertyName("minThreshold")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Minimal chegara 0 dan katta bo'lishi kerak")]
    decimal MinThreshold,

    [property: JsonPropertyName("unit")] int Unit,
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary = false
);

public record UpdateProductRequest(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("name")]
    [param: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [param: StringLength(200, MinimumLength = 1)]
    string Name,

    [property: JsonPropertyName("costPrice")]
    [param: Range(0, double.MaxValue)]
    decimal CostPrice,

    [property: JsonPropertyName("salePrice")]
    [param: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [param: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("quantity")]
    [param: Range(0, double.MaxValue)]
    decimal Quantity,

    [property: JsonPropertyName("minThreshold")]
    [param: Range(0, double.MaxValue)]
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
    [property: JsonPropertyName("isLowStock")] bool IsLowStock,
    // Server-nisbiy URL yoki null. Faqat savdo (POS) ekranida ko'rsatish uchun.
    [property: JsonPropertyName("imageUrl")] string? ImageUrl = null,
    // True bo'lsa — bu mahsulot narxi POS oqimida Seller roliga yashiriladi
    // (klient tomonida gate qilinadi). Mahsulotlar bo'limida narx baribir ko'rinadi.
    [property: JsonPropertyName("hidePriceFromSellers")] bool HidePriceFromSellers = false
);

/// <summary>
/// Mahsulot rasmini JSON orqali yuklash tanasi: "data:image/...;base64,..."
/// yoki to'g'ridan-to'g'ri base64 satr. (Multipart yuborishda ishlatilmaydi.)
/// </summary>
public record SetProductImageRequest(
    [property: JsonPropertyName("image")] string? Image
);

public record CreateZakupRequest(
    [property: JsonPropertyName("productId")]
    [param: Required]
    Guid ProductId,

    [property: JsonPropertyName("quantity")]
    [param: Range(0.001, double.MaxValue, ErrorMessage = "Miqdor 0 dan katta bo'lishi kerak")]
    decimal Quantity,

    [property: JsonPropertyName("costPrice")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Narx manfiy bo'lishi mumkin emas")]
    decimal CostPrice
);

// .NET 9 records: validation attributes attached via `[property:]` only land
// on the generated property — but ASP.NET Core's model binder validates the
// PARAMETER (the constructor argument). That mismatch throws
// "validation metadata defined on property X that will be ignored" at runtime.
// Use `[param:]` for validators so they bind to the parameter; keep
// `[property:]` for serialization-only attributes (JsonPropertyName) since
// the JSON reflection target is the property.
public record CreateProductDto(
    [property: JsonPropertyName("name")]
    [param: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [param: StringLength(200, MinimumLength = 1)]
    string Name,

    [property: JsonPropertyName("isTemporary")] bool IsTemporary,

    [property: JsonPropertyName("salePrice")]
    [param: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [param: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("minThreshold")]
    [param: Range(0, double.MaxValue)]
    decimal MinThreshold,

    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("unit")] int Unit = 1,

    // Boshlang'ich qoldiq — zakup orqali kelmagan, lekin do'konda allaqachon
    // bor tovarlar uchun. 0 bo'lsa, qoldiq keyin zakup orqali to'ldiriladi.
    [property: JsonPropertyName("quantity")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Miqdor manfiy bo'lishi mumkin emas")]
    decimal Quantity = 0,

    [property: JsonPropertyName("hidePriceFromSellers")] bool HidePriceFromSellers = false
);

public record UpdateProductDto(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("name")]
    [param: Required(ErrorMessage = "Mahsulot nomi majburiy")]
    [param: StringLength(200, MinimumLength = 1)]
    string Name,

    [property: JsonPropertyName("salePrice")]
    [param: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [param: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("minThreshold")]
    [param: Range(0, double.MaxValue)]
    decimal MinThreshold,

    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("unit")] int Unit = 1,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary = false,
    [property: JsonPropertyName("hidePriceFromSellers")] bool HidePriceFromSellers = false
);
