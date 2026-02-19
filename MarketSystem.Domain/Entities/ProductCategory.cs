using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class ProductCategory : BaseEntity
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int? MarketId { get; set; }  // ✅ Market-scoped categories
    public bool IsActive { get; set; } = true;

    // ✅ Navigation property
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
