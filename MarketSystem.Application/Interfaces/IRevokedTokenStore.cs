namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Tracks JWT access-token <c>jti</c> claims that have been explicitly revoked
/// (logout, refresh-token rotation, suspicious refresh, …) before their natural
/// expiry. The check runs on every authenticated request via the JwtBearer
/// <c>OnTokenValidated</c> event.
///
/// In a single-process deployment the in-memory implementation is enough — a
/// process restart clears the list but access tokens themselves expire in
/// 30 minutes, so the blast radius is bounded. For multi-replica setups,
/// swap to a Redis-backed store with the same interface.
/// </summary>
public interface IRevokedTokenStore
{
    /// <summary>
    /// Mark a jti as revoked. <paramref name="expiresAt"/> is the original
    /// access-token expiry — the entry is automatically dropped once it
    /// passes, since the token would be rejected anyway.
    /// </summary>
    void Revoke(string jti, DateTime expiresAtUtc);

    /// <summary>True if the jti is currently in the revocation list.</summary>
    bool IsRevoked(string jti);
}
