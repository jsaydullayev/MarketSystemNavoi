using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

/// <summary>
/// Audit log for debt price changes
/// Tracks all price modifications in debts (both open and closed)
/// </summary>
public class DebtAuditLog : BaseEntity
{
    public Guid SaleId { get; set; }
    public Guid SaleItemId { get; set; }
    public decimal OldPrice { get; set; }
    public decimal NewPrice { get; set; }
    public Guid ChangedByUserId { get; set; }
    public string Comment { get; set; } = string.Empty;

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
    public SaleItem SaleItem { get; set; } = null!;
    public User ChangedByUser { get; set; } = null!;
}
