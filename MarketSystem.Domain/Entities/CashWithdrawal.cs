using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class CashWithdrawal : BaseEntity
{
    public new Guid Id { get; set; }
    public decimal Amount { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime WithdrawalDate { get; set; }
    public string WithdrawType { get; set; } = "cash"; // 'cash' or 'click'
    public Guid? UserId { get; set; } // Kim olgani
    public User? User { get; set; }
}
