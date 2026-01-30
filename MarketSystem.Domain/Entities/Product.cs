using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class Product : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public bool IsTemporary { get; set; } = false;
    public Guid? CreatedBySellerId { get; set; }

    // Navigation properties
    public User? CreatedBySeller { get; set; }
    public ICollection<SaleItem> SaleItems { get; set; } = new List<SaleItem>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();
}
