using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class ProductCategory : ISoftDeletable
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int MarketId { get; set; }  // ✅ Market-scoped (NOT nullable!)
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
    public DateTime? DeletedAt { get; set; }

    // ✅ Navigation property
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
