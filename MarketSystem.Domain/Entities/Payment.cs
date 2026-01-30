using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class Payment : BaseEntity
{
    public Guid SaleId { get; set; }
    public PaymentType PaymentType { get; set; }
    public decimal Amount { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
}
