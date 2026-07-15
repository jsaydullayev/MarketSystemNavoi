using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class Zakup : BaseEntity
{
    public Guid ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal CostPrice { get; set; }
    public Guid CreatedByAdminId { get; set; }

    // Goods-receipt grouping. A Zakup is one product line of a ZakupReceipt
    // (priyomka). Nullable for legacy rows created before the receipt model;
    // the AddSupplierAndZakupReceipt migration back-fills a 1-line receipt for
    // each, and every new line always carries a ReceiptId.
    public Guid? ReceiptId { get; set; }
    public ZakupReceipt? Receipt { get; set; }

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public Product Product { get; set; } = null!;
    public User CreatedByAdmin { get; set; } = null!;
}
