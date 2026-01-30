using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class BranchProduct : BaseEntity
{
    public Guid BranchId { get; set; }
    public Guid ProductId { get; set; }
    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public decimal MinSalePrice { get; set; }
    public decimal Quantity { get; set; }
    public decimal MinThreshold { get; set; }

    // Navigation properties
    public Branch Branch { get; set; } = null!;
    public Product Product { get; set; } = null!;
}
