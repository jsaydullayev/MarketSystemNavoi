using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class Product : BaseEntity, ISoftDelete
{
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Mahsulot rasmiga server-nisbiy URL, masalan "/uploads/products/12/abc.webp".
    /// Null = rasmsiz (ko'pchilik tovarlar uchun odatiy holat). Rasm fayli diskda
    /// (persistent volume) saqlanadi; bu yerda faqat qisqa yo'l turadi.
    /// </summary>
    public string? ImageUrl { get; set; }

    public bool IsTemporary { get; set; } = false;
    public Guid? CreatedBySellerId { get; set; }
    public bool IsDeleted { get; set; } = false;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? DeletedAt { get; set; }

    // Pricing
    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public decimal MinSalePrice { get; set; }

    /// <summary>
    /// True bo'lsa, bu mahsulotning narxi sotuv (POS) oqimida Seller roliga
    /// ko'rsatilmaydi — kassir narxni qo'lda kiritadi. Mahsulotlar bo'limida
    /// narx baribir ko'rinadi. Admin/Owner mahsulot formasidan boshqaradi.
    /// </summary>
    public bool HidePriceFromSellers { get; set; } = false;

    // Stock - DECIMAL qilib o'zgartirdik (1.5 kg bo'lishi mumkin)
    public decimal Quantity { get; set; }
    public decimal MinThreshold { get; set; } = 5m;

    // Optimistic concurrency token. Mapped to PostgreSQL's hidden xmin column
    // so concurrent stock changes detect each other and surface a 409.
    public uint Xmin { get; set; }

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
