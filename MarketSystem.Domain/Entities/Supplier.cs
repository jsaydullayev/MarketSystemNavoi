using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

/// <summary>
/// A goods supplier (yetkazib beruvchi) the shop buys stock from. Mirrors the
/// <see cref="Customer"/> shape: a soft-deletable, market-scoped directory
/// entry that goods-receipts (<see cref="ZakupReceipt"/>) reference so the shop
/// can track how much it owes each supplier.
/// </summary>
public class Supplier : BaseEntity, ISoftDelete
{
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string? Comment { get; set; }
    public bool IsDeleted { get; set; } = false;

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public ICollection<ZakupReceipt> Receipts { get; set; } = new List<ZakupReceipt>();
}
