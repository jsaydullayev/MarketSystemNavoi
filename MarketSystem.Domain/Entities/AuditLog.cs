using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class AuditLog : BaseEntity
{
    public string EntityType { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public string Action { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string Payload { get; set; } = string.Empty;

    /// <summary>Client IP captured at write time — key for security review
    /// (e.g. which address a failed login came from). Null when unavailable.</summary>
    public string? IpAddress { get; set; }

    // Multi-tenancy — nullable so cross-tenant operations (e.g. SuperAdmin
    // approving a registration before a market exists) can still be logged.
    public int? MarketId { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
    public Market? Market { get; set; }
}
