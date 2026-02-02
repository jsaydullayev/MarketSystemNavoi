using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class RefreshToken : BaseEntity
{
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; } = false;
    public bool IsRevoked { get; set; } = false;
    public DateTime? RevokedAt { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
}
