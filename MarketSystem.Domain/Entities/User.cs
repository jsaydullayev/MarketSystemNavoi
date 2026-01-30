using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class User : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public Role Role { get; set; }
    public Guid BranchId { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public Branch Branch { get; set; } = null!;
    public ICollection<Sale> Sales { get; set; } = new List<Sale>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    public ICollection<Product> TemporaryProducts { get; set; } = new List<Product>();
}
