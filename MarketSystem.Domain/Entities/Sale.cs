using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class Sale : BaseEntity, ISoftDelete
{
    public Guid SellerId { get; set; }
    public Guid? CustomerId { get; set; }
    public SaleStatus Status { get; set; } = SaleStatus.Draft;
    public decimal TotalAmount { get; set; }
    public decimal PaidAmount { get; set; }
    public bool IsDeleted { get; set; } = false;

    // When the sale was soft-deleted (Owner data-cleanup). Null while active.
    // Paired with IsDeleted so a destructive delete is auditable and reversible.
    public DateTime? DeletedAt { get; set; }

    // Optimistic concurrency token. Mapped to PostgreSQL's built-in xmin column
    // so concurrent payment / cancellation writes detect each other instead of
    // silently overwriting Status (Paid vs Debt vs Cancelled).
    public uint Xmin { get; set; }

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public User Seller { get; set; } = null!;
    public Customer? Customer { get; set; }
    public ICollection<SaleItem> SaleItems { get; set; } = new List<SaleItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    public Debt? Debt { get; set; }
}
