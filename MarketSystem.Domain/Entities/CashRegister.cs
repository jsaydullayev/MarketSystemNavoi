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

    // K2 — optimistic concurrency token mapped to PostgreSQL's system
    // column "xmin". Concurrent AddCash / WithdrawCash on the same per-market
    // register used to lose updates: two callers each read CurrentBalance=100,
    // each subtract their amount, both save → the later write clobbers the
    // earlier. With Xmin, the loser fails with DbUpdateConcurrencyException
    // and ExecuteInTransactionAsync's PostgreSQL retry replays correctly.
    // No DDL change — xmin already exists on every PostgreSQL table.
    public uint Xmin { get; set; }
}
