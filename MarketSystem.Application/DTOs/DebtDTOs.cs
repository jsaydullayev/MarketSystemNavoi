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

/// <summary>
/// Qarz hisobiga tushgan bitta to'lov. `Payment` jadvalida qarzning ota-sotuvi
/// (SaleId) bo'yicha saqlanadi — Debt'ga to'g'ridan-to'g'ri FK yo'q.
/// </summary>
public record DebtPaymentDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("saleId")] Guid SaleId,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);

/// <summary>
/// Bitta qarzdorning yig'ma ko'rinishi. Bitta mijoz bir necha marta qarz olishi
/// mumkin, shuning uchun qarzdor kartasiga bosilganda uchta asosiy raqam kerak:
///   • <see cref="TotalDebt"/> — jami qoldiq qarz (barcha ochiq qarzlar bo'yicha);
///   • <see cref="LastDebtAmount"/> — oxirgi (ya'ni hozirgi) olingan qarz summasi;
///   • <see cref="LastPaymentAmount"/> — oxirgi marta qarzga to'langan summa.
/// Aynan shu DTO PDF eksportga ham asos bo'ladi, shuning uchun ekran va PDF
/// raqamlari hech qachon farq qilmaydi.
/// </summary>
public record CustomerDebtSummaryDto(
    [property: JsonPropertyName("customerId")] Guid CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("customerPhone")] string? CustomerPhone,
    // Ochiq qarzlarning qoldiq yig'indisi — "jami qarz".
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt,
    // Ochiq qarzlarning boshlang'ich (olingan) summalari yig'indisi.
    [property: JsonPropertyName("totalOriginalDebt")] decimal TotalOriginalDebt,
    // Ochiq qarzlar bo'yicha shu vaqtga qadar to'langan summa.
    [property: JsonPropertyName("totalPaid")] decimal TotalPaid,
    [property: JsonPropertyName("openDebtCount")] int OpenDebtCount,
    // Oxirgi olingan qarzning boshlang'ich summasi.
    [property: JsonPropertyName("lastDebtAmount")] decimal LastDebtAmount,
    // Oxirgi olingan qarzning hozirgi qoldig'i.
    [property: JsonPropertyName("lastDebtRemaining")] decimal LastDebtRemaining,
    [property: JsonPropertyName("lastDebtDate")] DateTime? LastDebtDate,
    [property: JsonPropertyName("lastPaymentAmount")] decimal LastPaymentAmount,
    [property: JsonPropertyName("lastPaymentType")] string? LastPaymentType,
    [property: JsonPropertyName("lastPaymentDate")] DateTime? LastPaymentDate,
    [property: JsonPropertyName("oldestDebtDate")] DateTime? OldestDebtDate,
    // Oxirgi to'lovlar (eng yangisi birinchi), ko'pi bilan 10 ta.
    [property: JsonPropertyName("recentPayments")] List<DebtPaymentDto> RecentPayments
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
