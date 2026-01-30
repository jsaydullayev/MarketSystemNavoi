using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class SaleItem : BaseEntity
{
    public Guid SaleId { get; set; }
    public Guid ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public string? Comment { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
    public Product Product { get; set; } = null!;

    // Computed property
    public decimal Profit => (SalePrice - CostPrice) * Quantity;
}
