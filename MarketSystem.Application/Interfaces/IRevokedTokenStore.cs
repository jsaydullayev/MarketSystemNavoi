namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Tracks JWT access-token <c>jti</c> claims that have been explicitly revoked
/// (logout, refresh-token rotation, suspicious refresh, …) before their natural
/// expiry. The check runs on every authenticated request via the JwtBearer
/// <c>OnTokenValidated</c> event.
///
/// Implementations must be:
/// - Fast on <see cref="IsRevoked"/> — called on every authenticated request.
/// - Durable on <see cref="RevokeAsync"/> — persisted so revocations survive
///   process restarts and are visible across multiple replicas.
/// </summary>
public interface IRevokedTokenStore
{
    /// <summary>
    /// Mark a jti as revoked. <paramref name="expiresAtUtc"/> is the original
    /// access-token expiry — the entry is automatically dropped once it passes.
    /// </summary>
    Task RevokeAsync(string jti, DateTime expiresAtUtc, CancellationToken ct = default);

    /// <summary>True if the jti is currently in the revocation list.</summary>
    bool IsRevoked(string jti);
}
