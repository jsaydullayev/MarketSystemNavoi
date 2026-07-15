using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

// ── Read DTOs ───────────────────────────────────────────────────────────────

/// <summary>One product line of a goods-receipt (full — includes cost).</summary>
public record ZakupReceiptLineDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("lineTotal")] decimal LineTotal
);

/// <summary>Seller-safe line — cost price and totals stripped.</summary>
public record ZakupReceiptLineSellerDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity
);

/// <summary>Full goods-receipt header + its lines (Owner/Admin view).</summary>
public record ZakupReceiptDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("supplierId")] Guid? SupplierId,
    [property: JsonPropertyName("supplierName")] string? SupplierName,
    [property: JsonPropertyName("invoiceNumber")] string? InvoiceNumber,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("paidAmount")] decimal PaidAmount,
    [property: JsonPropertyName("outstandingAmount")] decimal OutstandingAmount,
    [property: JsonPropertyName("paymentStatus")] string PaymentStatus,
    [property: JsonPropertyName("comment")] string? Comment,
    [property: JsonPropertyName("itemCount")] int ItemCount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("createdBy")] string CreatedBy,
    [property: JsonPropertyName("items")] IReadOnlyList<ZakupReceiptLineDto> Items
);

/// <summary>Seller-safe receipt — no cost, totals, or payment figures.</summary>
public record ZakupReceiptSellerDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("supplierId")] Guid? SupplierId,
    [property: JsonPropertyName("supplierName")] string? SupplierName,
    [property: JsonPropertyName("invoiceNumber")] string? InvoiceNumber,
    [property: JsonPropertyName("itemCount")] int ItemCount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("createdBy")] string CreatedBy,
    [property: JsonPropertyName("items")] IReadOnlyList<ZakupReceiptLineSellerDto> Items
);

// ── Write DTOs ──────────────────────────────────────────────────────────────

public record CreateZakupLineDto(
    [property: JsonPropertyName("productId")]
    [param: Required(ErrorMessage = "Mahsulot majburiy")]
    Guid ProductId,

    [property: JsonPropertyName("quantity")]
    [param: Range(0.0001, double.MaxValue, ErrorMessage = "Soni 0 dan katta bo'lishi kerak")]
    decimal Quantity,

    [property: JsonPropertyName("costPrice")]
    [param: Range(0, double.MaxValue, ErrorMessage = "Narx manfiy bo'lishi mumkin emas")]
    decimal CostPrice
);

public record CreateZakupReceiptDto(
    [property: JsonPropertyName("supplierId")] Guid? SupplierId,

    [property: JsonPropertyName("invoiceNumber")]
    [param: StringLength(100, ErrorMessage = "Nakladnoy raqami 100 belgidan oshmasligi kerak")]
    string? InvoiceNumber,

    [property: JsonPropertyName("paidAmount")]
    [param: Range(0, double.MaxValue, ErrorMessage = "To'langan summa manfiy bo'lishi mumkin emas")]
    decimal PaidAmount,

    [property: JsonPropertyName("comment")]
    [param: StringLength(500, ErrorMessage = "Izoh 500 belgidan oshmasligi kerak")]
    string? Comment,

    [property: JsonPropertyName("items")]
    [param: Required(ErrorMessage = "Kamida bitta mahsulot kerak")]
    [param: MinLength(1, ErrorMessage = "Kamida bitta mahsulot kerak")]
    List<CreateZakupLineDto> Items
);

/// <summary>Register an additional payment toward a receipt's supplier debt.</summary>
public record RegisterSupplierPaymentDto(
    [property: JsonPropertyName("amount")]
    [param: Range(0.01, double.MaxValue, ErrorMessage = "To'lov summasi 0 dan katta bo'lishi kerak")]
    decimal Amount
);
