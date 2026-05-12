namespace MarketSystem.Domain.Entities;

public class CashRegister
{
    public Guid Id { get; set; }
    public decimal CurrentBalance { get; set; }
    public DateTime LastUpdated { get; set; }
    public Guid? LastWithdrawalId { get; set; }

    // Multi-tenancy: each Market owns exactly one CashRegister.
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    public CashWithdrawal? LastWithdrawal { get; set; }
}
