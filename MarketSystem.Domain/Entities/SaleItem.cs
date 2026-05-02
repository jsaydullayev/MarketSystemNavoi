using MarketSystem.Domain.Common;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketSystem.Domain.Entities;

public class SaleItem : BaseEntity
{
    public Guid SaleId { get; set; }

    // ✅ TASHQI MAHSULOT FLAG
    public bool IsExternal { get; set; } = false;

    // ✅ ORDINARY PRODUCT (Oddiy mahsulot) - Nullable
    public Guid? ProductId { get; set; }

    // ✅ EXTERNAL PRODUCT (Tashqi mahsulot) - faqat IsExternal = true bo'lganda
    public string? ExternalProductName { get; set; }
    public decimal ExternalCostPrice { get; set; }

    // Quantity - DECIMAL qilib o'zgartirdik
    public decimal Quantity { get; set; }

    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public string? Comment { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;

    // ✅ Nullable navigation property
    public Product? Product { get; set; }

    /// <summary>
    /// Effective cost price calculation (External for external products, otherwise Product.CostPrice)
    /// </summary>
    [NotMapped]
    public decimal EffectiveCostPrice => IsExternal
        ? ExternalCostPrice
        : (Product?.CostPrice ?? 0);

    /// <summary>
    /// Jami summa (Quantity * SalePrice)
    /// </summary>
    public decimal TotalPrice => Quantity * SalePrice;

    /// <summary>
    /// Foyda (SalePrice - EffectiveCostPrice) * Quantity
    /// </summary>
    public decimal Profit => (SalePrice - EffectiveCostPrice) * Quantity;

    /// <summary>
    /// Jami xaraj narx (Quantity * EffectiveCostPrice)
    /// </summary>
    public decimal TotalCost => Quantity * EffectiveCostPrice;
}
