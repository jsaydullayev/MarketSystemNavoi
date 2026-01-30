using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class Sale : BaseEntity
{
    public Guid BranchId { get; set; }
    public Guid SellerId { get; set; }
    public Guid? CustomerId { get; set; }
    public SaleStatus Status { get; set; } = SaleStatus.Draft;
    public decimal TotalAmount { get; set; }
    public decimal PaidAmount { get; set; }

    // Navigation properties
    public Branch Branch { get; set; } = null!;
    public User Seller { get; set; } = null!;
    public Customer? Customer { get; set; }
    public ICollection<SaleItem> SaleItems { get; set; } = new List<SaleItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    public Debt? Debt { get; set; }
}
