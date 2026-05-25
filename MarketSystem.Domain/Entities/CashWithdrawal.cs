using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class CashWithdrawal : BaseEntity
{
    public decimal Amount { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime WithdrawalDate { get; set; }
    public string WithdrawType { get; set; } = "cash"; // 'cash' or 'click'

    /// <summary>
    /// Tenant scope. Always set from <c>ICurrentMarketService</c> when the row
    /// is created — never inferred from <see cref="UserId"/> at read time,
    /// otherwise orphan rows (UserId=null after a user is hard-deleted) leak
    /// across tenants. See K2 in the security audit.
    /// </summary>
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    public Guid? UserId { get; set; } // Kim olgani
    public User? User { get; set; }
}
