using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record DebtDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("saleId")] Guid SaleId,
    [property: JsonPropertyName("customerId")] Guid CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt,
    [property: JsonPropertyName("remainingDebt")] decimal RemainingDebt,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("dueDate")] DateTime? DueDate,
    [property: JsonPropertyName("saleItems")] List<SaleItemDto>? SaleItems
);

public record DebtorDto(
    [property: JsonPropertyName("customerId")] Guid CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("customerPhone")] string? CustomerPhone,
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt,
    [property: JsonPropertyName("paidAmount")] decimal PaidAmount,
    [property: JsonPropertyName("remainingDebt")] decimal RemainingDebt,
    [property: JsonPropertyName("debtCount")] int DebtCount,
    [property: JsonPropertyName("oldestDebtDate")] DateTime? OldestDebtDate,
    [property: JsonPropertyName("sales")] List<SaleDto> Sales
);

public record PayDebtDto(
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("paymentType")] string PaymentType
);

public record PayDebtResultDto(
    decimal RemainingDebt,
    decimal PaymentAmount,
    string DebtStatus
);

/// <summary>
/// Qarzning to'lov muddatini (due date) yangilash tanasi. Null yuborilsa —
/// muddat olib tashlanadi.
/// </summary>
public record UpdateDebtDueDateDto(
    [property: JsonPropertyName("dueDate")] DateTime? DueDate
);
