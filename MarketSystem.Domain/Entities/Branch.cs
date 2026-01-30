using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class Branch : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? Phone { get; set; }

    // Navigation properties
    public ICollection<BranchProduct> BranchProducts { get; set; } = new List<BranchProduct>();
    public ICollection<Sale> Sales { get; set; } = new List<Sale>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();
}
