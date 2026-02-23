using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class SaleItem : BaseEntity
{
    public Guid SaleId { get; set; }
    public Guid ProductId { get; set; }

    // Quantity - DECIMAL qilib o'zgartirdik
    public decimal Quantity { get; set; }

    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public string? Comment { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
    public Product Product { get; set; } = null!;

    /// <summary>
    /// Jami summa (Quantity * SalePrice)
    /// </summary>
    public decimal TotalPrice => Quantity * SalePrice;

    /// <summary>
    /// Foyda (SalePrice - CostPrice) * Quantity
    /// </summary>
    public decimal Profit => (SalePrice - CostPrice) * Quantity;

    /// <summary>
    /// Jami xaraj narx (Quantity * CostPrice)
    /// </summary>
    public decimal TotalCost => Quantity * CostPrice;
}
