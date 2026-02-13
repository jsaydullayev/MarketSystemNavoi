using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public class CashRegisterDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("currentBalance")]
    public decimal CurrentBalance { get; set; }

    [JsonPropertyName("lastUpdated")]
    public DateTime LastUpdated { get; set; }

    [JsonPropertyName("withdrawals")]
    public List<CashWithdrawalDto> Withdrawals { get; set; } = new();
}

public class CashWithdrawalDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("amount")]
    public decimal Amount { get; set; }

    [JsonPropertyName("comment")]
    public string Comment { get; set; } = string.Empty;

    [JsonPropertyName("withdrawalDate")]
    public DateTime WithdrawalDate { get; set; }

    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}

public class WithdrawCashRequest
{
    [JsonPropertyName("amount")]
    public decimal Amount { get; set; }

    [JsonPropertyName("comment")]
    public string Comment { get; set; } = string.Empty;
}

public class TodaySalesSummaryDto
{
    [JsonPropertyName("totalSales")]
    public int TotalSales { get; set; }

    [JsonPropertyName("totalAmount")]
    public decimal TotalAmount { get; set; }

    [JsonPropertyName("totalPaid")]
    public decimal TotalPaid { get; set; }

    [JsonPropertyName("cashPaid")]
    public decimal CashPaid { get; set; }

    [JsonPropertyName("cardPaid")]
    public decimal CardPaid { get; set; }

    [JsonPropertyName("date")]
    public DateTime Date { get; set; }
}
