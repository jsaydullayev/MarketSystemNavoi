namespace MarketSystem.Domain.Entities;

/// <summary>
/// Persisted record of a revoked JWT access-token jti.
/// Loaded into memory on startup so IsRevoked() checks are O(1) in-memory
/// lookups without hitting the database on every request.
/// </summary>
public class RevokedToken
{
    public int Id { get; set; }
    public string Jti { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
    public DateTime RevokedAtUtc { get; set; } = DateTime.UtcNow;
}
