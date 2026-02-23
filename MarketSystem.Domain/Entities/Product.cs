using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class Product : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public bool IsTemporary { get; set; } = false;
    public Guid? CreatedBySellerId { get; set; }
    public bool IsDeleted { get; set; } = false;

    // Pricing
    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public decimal MinSalePrice { get; set; }

    // Stock - DECIMAL qilib o'zgartirdik (1.5 kg bo'lishi mumkin)
    public decimal Quantity { get; set; }
    public decimal MinThreshold { get; set; } = 5m;

    // ✅ Unit Type - YANGI
    public UnitType Unit { get; set; } = UnitType.Piece;

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Category
    public int? CategoryId { get; set; }
    public ProductCategory? Category { get; set; }

    // Navigation properties
    public User? CreatedBySeller { get; set; }
    public ICollection<SaleItem> SaleItems { get; set; } = new List<SaleItem>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();

    /// <summary>
    /// Omborda mavjudligini tekshirish
    /// </summary>
    public bool IsInStock(decimal requestedQuantity)
    {
        return Quantity >= requestedQuantity;
    }

    /// <summary>
    /// Minimal miqdordan pastga tushganmi
    /// </summary>
    public bool IsLowStock => Quantity <= MinThreshold;

    /// <summary>
    /// Unit nomini olish (uzbek)
    /// </summary>
    public string GetUnitName()
    {
        return Unit switch
        {
            UnitType.Piece => "dona",
            UnitType.Kilogram => "kg",
            UnitType.Meter => "m",
            _ => "noma'lum"
        };
    }
}
