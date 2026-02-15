using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class Zakup : BaseEntity
{
    public Guid ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal CostPrice { get; set; }
    public Guid CreatedByAdminId { get; set; }

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public Product Product { get; set; } = null!;
    public User CreatedByAdmin { get; set; } = null!;
}
