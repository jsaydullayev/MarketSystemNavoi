using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class Customer : BaseEntity, ISoftDelete
{
    public string Phone { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string? Comment { get; set; }
    public bool IsDeleted { get; set; } = false;

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public ICollection<Sale> Sales { get; set; } = new List<Sale>();
    public ICollection<Debt> Debts { get; set; } = new List<Debt>();
}
