using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

/// <summary>
/// A goods-receipt header (priyomka) — one delivery from a supplier that may
/// contain several product line items (<see cref="Zakup"/>). Groups the lines,
/// carries the supplier/invoice reference and the payment state toward the
/// supplier, so a single delivery of many products is recorded as one document
/// rather than N disconnected purchases.
/// </summary>
public class ZakupReceipt : BaseEntity
{
    /// <summary>Optional — a quick re-stock may have no named supplier.</summary>
    public Guid? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    /// <summary>Supplier's invoice / nakladnoy number, free text.</summary>
    public string? InvoiceNumber { get; set; }

    /// <summary>Sum of every line's Quantity * CostPrice.</summary>
    public decimal TotalAmount { get; set; }

    /// <summary>How much of <see cref="TotalAmount"/> has been paid so far.</summary>
    public decimal PaidAmount { get; set; }

    /// <summary>Derived from Paid vs Total; stored for cheap balance queries.</summary>
    public SupplierPaymentStatus PaymentStatus { get; set; } = SupplierPaymentStatus.Unpaid;

    public string? Comment { get; set; }

    public Guid CreatedByAdminId { get; set; }
    public User CreatedByAdmin { get; set; } = null!;

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Optimistic concurrency (PostgreSQL system column xmin) — guards concurrent
    // supplier-payment updates from clobbering each other's PaidAmount/status.
    public uint Xmin { get; set; }

    // Navigation properties — the product lines received in this delivery.
    public ICollection<Zakup> Items { get; set; } = new List<Zakup>();

    /// <summary>Outstanding amount still owed to the supplier for this receipt.</summary>
    public decimal OutstandingAmount => TotalAmount - PaidAmount;
}
