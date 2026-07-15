using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record SupplierDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("phone")] string? Phone,
    [property: JsonPropertyName("address")] string? Address,
    [property: JsonPropertyName("comment")] string? Comment,
    // Sum of (TotalAmount - PaidAmount) across this supplier's receipts — how
    // much the shop still owes. Cost-sensitive; the controller redacts it for
    // Sellers just like customer debt.
    [property: JsonPropertyName("outstandingDebt")] decimal OutstandingDebt,
    [property: JsonPropertyName("receiptCount")] int ReceiptCount
);

public record CreateSupplierDto(
    [property: JsonPropertyName("name")]
    [param: Required(ErrorMessage = "Nomi majburiy")]
    [param: StringLength(200, ErrorMessage = "Nomi 200 belgidan oshmasligi kerak")]
    string Name,

    [property: JsonPropertyName("phone")]
    [param: StringLength(20, ErrorMessage = "Telefon 20 belgidan oshmasligi kerak")]
    string? Phone,

    [property: JsonPropertyName("address")]
    [param: StringLength(300, ErrorMessage = "Manzil 300 belgidan oshmasligi kerak")]
    string? Address,

    [property: JsonPropertyName("comment")]
    [param: StringLength(500, ErrorMessage = "Izoh 500 belgidan oshmasligi kerak")]
    string? Comment
);

public record UpdateSupplierDto(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("name")]
    [param: StringLength(200, ErrorMessage = "Nomi 200 belgidan oshmasligi kerak")]
    string? Name,

    [property: JsonPropertyName("phone")]
    [param: StringLength(20, ErrorMessage = "Telefon 20 belgidan oshmasligi kerak")]
    string? Phone,

    [property: JsonPropertyName("address")]
    [param: StringLength(300, ErrorMessage = "Manzil 300 belgidan oshmasligi kerak")]
    string? Address,

    [property: JsonPropertyName("comment")]
    [param: StringLength(500, ErrorMessage = "Izoh 500 belgidan oshmasligi kerak")]
    string? Comment
);

public record SupplierDeleteInfoDto(
    [property: JsonPropertyName("canDelete")] bool CanDelete,
    [property: JsonPropertyName("receiptsCount")] int ReceiptsCount,
    [property: JsonPropertyName("outstandingDebt")] decimal OutstandingDebt,
    [property: JsonPropertyName("warningMessage")] string? WarningMessage
);
