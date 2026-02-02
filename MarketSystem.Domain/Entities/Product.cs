using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class Product : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public bool IsTemporary { get; set; } = false;
    public Guid? CreatedBySellerId { get; set; }

    // Pricing (since Branch is removed, prices are in Product)
    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public decimal MinSalePrice { get; set; }

    // Stock
    public int Quantity { get; set; }
    public int MinThreshold { get; set; } = 5;

    // Navigation properties
    public User? CreatedBySeller { get; set; }
    public ICollection<SaleItem> SaleItems { get; set; } = new List<SaleItem>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();
}
