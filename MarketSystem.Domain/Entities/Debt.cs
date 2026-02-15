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

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
    public Customer Customer { get; set; } = null!;
}
