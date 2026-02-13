namespace MarketSystem.Application.DTOs;

public class CashRegisterDto
{
    public Guid Id { get; set; }
    public decimal CurrentBalance { get; set; }
    public DateTime LastUpdated { get; set; }
    public List<CashWithdrawalDto> Withdrawals { get; set; } = new();
}

public class CashWithdrawalDto
{
    public Guid Id { get; set; }
    public decimal Amount { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime WithdrawalDate { get; set; }
    public string? UserName { get; set; }
}

public class WithdrawCashRequest
{
    public decimal Amount { get; set; }
    public string Comment { get; set; } = string.Empty;
}
