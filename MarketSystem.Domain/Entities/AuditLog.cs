using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class AuditLog : BaseEntity
{
    public string EntityType { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public string Action { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string Payload { get; set; } = string.Empty;

    // Navigation properties
    public User User { get; set; } = null!;
}
