using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class Debt : BaseEntity
{
    public Guid SaleId { get; set; }
    public Guid CustomerId { get; set; }
    public decimal TotalDebt { get; set; }
    public decimal RemainingDebt { get; set; }
    public DebtStatus Status { get; set; } = DebtStatus.Open;
    public DateTime? DueDate { get; set; }

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
    public Customer Customer { get; set; } = null!;

    // K3 — optimistic concurrency token mapped to PostgreSQL's "xmin". Without
    // it, two concurrent writes to RemainingDebt (e.g. PayAsync racing with
    // CancelSaleAsync's debt-close, or two parallel partial-payment calls)
    // could each read the same stale balance and the later save would
    // silently overwrite the earlier — losing money on the customer's
    // outstanding balance. Xmin makes the second write fail with
    // DbUpdateConcurrencyException; the surrounding ExecuteInTransactionAsync
    // retries from a fresh read.
    public uint Xmin { get; set; }
}
