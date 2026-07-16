using System.ComponentModel.DataAnnotations;
using MarketSystem.Domain.Enums;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record CreateSaleRequest(Guid SellerId, Guid? CustomerId);
public record AddSaleItemRequest(Guid SaleId, Guid ProductId, decimal Quantity, decimal CostPrice, decimal SalePrice, string? Comment);
public record ReturnSaleItemRequest(string SaleItemId, decimal Quantity, string? Comment);
public record AddPaymentRequest(Guid SaleId, PaymentType PaymentType, decimal Amount);
public record SaleItemResponse(Guid Id, Guid ProductId, string ProductName, decimal Quantity, decimal CostPrice, decimal SalePrice, decimal TotalPrice, decimal Profit, string Unit, string? Comment);
public record PaymentResponse(Guid Id, PaymentType PaymentType, decimal Amount, DateTime CreatedAt);
public record SaleResponse(Guid Id, Guid SellerId, SaleStatus Status, decimal TotalAmount, decimal PaidAmount, decimal RemainingAmount, ICollection<SaleItemResponse> Items, ICollection<PaymentResponse> Payments);

public record SaleItemDto(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("saleId")] string SaleId,
    [property: JsonPropertyName("productId")] Guid? ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalPrice")] decimal TotalPrice,
    [property: JsonPropertyName("profit")] decimal Profit,
    [property: JsonPropertyName("unit")] string Unit,
    [property: JsonPropertyName("comment")] string? Comment,
    [property: JsonPropertyName("isExternal")] bool IsExternal
);

public record PaymentDto(
    [property: JsonPropertyName("paymentId")] Guid PaymentId,
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("saleStatus")] string? SaleStatus,
    [property: JsonPropertyName("salePaidAmount")] decimal? SalePaidAmount,
    [property: JsonPropertyName("saleTotalAmount")] decimal? SaleTotalAmount
);

public record SaleDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("sellerId")] Guid SellerId,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("customerId")] Guid? CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("customerPhone")] string? CustomerPhone,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("paidAmount")] decimal PaidAmount,
    [property: JsonPropertyName("remainingAmount")] decimal RemainingAmount,
    [property: JsonPropertyName("discountAmount")] decimal DiscountAmount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("items")] List<SaleItemDto> Items,
    [property: JsonPropertyName("payments")] List<PaymentDto> Payments
);

public record CreateSaleDto(
    [property: JsonPropertyName("customerId")] Guid? CustomerId
);

public record UpdateSaleCustomerDto(
    [property: JsonPropertyName("customerId")] Guid? CustomerId
);

public record AddSaleItemDto(
    [property: JsonPropertyName("isExternal")] bool IsExternal,
    [property: JsonPropertyName("productId")] Guid? ProductId,

    [property: JsonPropertyName("externalProductName")]
    [param: StringLength(200, ErrorMessage = "Mahsulot nomi 200 belgidan oshmasligi kerak")]
    string? ExternalProductName,

    [property: JsonPropertyName("externalCostPrice")]
    [param: Range(0, double.MaxValue)]
    decimal? ExternalCostPrice,

    [property: JsonPropertyName("quantity")]
    [param: Range(0.001, double.MaxValue, ErrorMessage = "Miqdor 0 dan katta bo'lishi kerak")]
    decimal Quantity,

    [property: JsonPropertyName("salePrice")]
    [param: Range(0, double.MaxValue)]
    decimal SalePrice,

    [property: JsonPropertyName("minSalePrice")]
    [param: Range(0, double.MaxValue)]
    decimal MinSalePrice,

    [property: JsonPropertyName("comment")]
    [param: StringLength(500)]
    string? Comment
);

public record RemoveSaleItemDto(
    [property: JsonPropertyName("saleItemId")]
    [param: Required]
    string SaleItemId,

    [property: JsonPropertyName("quantity")]
    [param: Range(0.001, double.MaxValue, ErrorMessage = "Miqdor 0 dan katta bo'lishi kerak")]
    decimal Quantity
);

public record AddPaymentDto(
    [property: JsonPropertyName("paymentType")]
    [param: Required(ErrorMessage = "To'lov turi majburiy")]
    string PaymentType,

    [property: JsonPropertyName("amount")]
    [param: Range(0.01, double.MaxValue, ErrorMessage = "To'lov miqdori 0 dan katta bo'lishi kerak")]
    decimal Amount,

    // Qisman to'lov qarz qoldirsa — yaratilgan qarzning to'lov muddati
    // (ixtiyoriy). To'liq to'lovlarda e'tiborga olinmaydi.
    [property: JsonPropertyName("dueDate")] DateTime? DueDate = null
);

/// <summary>
/// Aralash (multi-tender) to'lov — bir savdo uchun barcha to'lov bo'laklari,
/// atomik qo'llanadi. Mijoz talabi bo'laklar YIG'INDISIGA qarab baholanadi, shu
/// sabab mijozsiz savdo ham naqd + karta bo'lib to'liq to'lanishi mumkin.
/// </summary>
public record AddPaymentsDto(
    [property: JsonPropertyName("payments")]
    [param: Required(ErrorMessage = "To'lov(lar) majburiy")]
    [param: MinLength(1, ErrorMessage = "Kamida bitta to'lov kiritilishi kerak")]
    IReadOnlyList<AddPaymentDto> Payments
);

/// <summary>
/// "Qarzga olish" (to'liq qarz) uchun ixtiyoriy to'lov muddati (due date).
/// </summary>
public record MarkSaleAsDebtDto(
    [property: JsonPropertyName("dueDate")] DateTime? DueDate = null
);

public record UpdateSaleItemPriceDto(
    [property: JsonPropertyName("saleItemId")]
    [param: Required]
    string SaleItemId,

    [property: JsonPropertyName("newPrice")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Narx manfiy bo'lishi mumkin emas")]
    decimal NewPrice,

    [property: JsonPropertyName("comment")]
    [param: StringLength(500)]
    string? Comment
);

/// <summary>
/// Sale-level chegirma (skidka) — kassa to'lov oynasida qo'llaniladi. Item
/// narxlariga tegmaydi; faqat sotuvning umumiy hisobini (TotalAmount) kamaytiradi.
/// </summary>
public record SetSaleDiscountDto(
    [property: JsonPropertyName("discountAmount")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Chegirma manfiy bo'lmasin")]
    decimal DiscountAmount
);
