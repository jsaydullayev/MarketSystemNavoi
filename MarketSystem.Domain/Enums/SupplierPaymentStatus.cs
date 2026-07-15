namespace MarketSystem.Domain.Enums;

/// <summary>
/// Payment state of a <see cref="MarketSystem.Domain.Entities.ZakupReceipt"/>
/// toward its supplier: how much of the goods-receipt total the shop has
/// already paid. Derived from PaidAmount vs TotalAmount, but stored so the
/// supplier-balance query and history filters stay cheap.
/// </summary>
public enum SupplierPaymentStatus
{
    /// <summary>Nothing paid yet — the full amount is owed to the supplier.</summary>
    Unpaid = 0,

    /// <summary>Some but not all of the total has been paid.</summary>
    Partial = 1,

    /// <summary>Fully paid — nothing owed.</summary>
    Paid = 2,
}
