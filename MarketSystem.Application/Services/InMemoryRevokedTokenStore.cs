using System.Collections.Concurrent;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.Application.Services;

/// <summary>
/// Process-local revocation list. Entries are pruned lazily on every access
/// after the access-token's original expiry, so the dictionary can never
/// grow without bound.
///
/// NOT shared across replicas — for a horizontally-scaled deployment swap
/// to a Redis-backed implementation of <see cref="IRevokedTokenStore"/>.
/// </summary>
public sealed class InMemoryRevokedTokenStore : IRevokedTokenStore
{
    private readonly ConcurrentDictionary<string, DateTime> _entries = new();

    public void Revoke(string jti, DateTime expiresAtUtc)
    {
        if (string.IsNullOrEmpty(jti)) return;
        // Keep the latest expiry on collision (paranoid double-revoke).
        _entries.AddOrUpdate(jti, expiresAtUtc, (_, existing) => existing > expiresAtUtc ? existing : expiresAtUtc);

        // Opportunistic prune on writes — keeps the dictionary small without a
        // background sweeper. We don't iterate the whole map on every revoke
        // because revokes are rare relative to validations.
        if (_entries.Count > 64 && _entries.Count % 32 == 0)
        {
            PruneExpired();
        }
    }

    public bool IsRevoked(string jti)
    {
        if (string.IsNullOrEmpty(jti)) return false;
        if (!_entries.TryGetValue(jti, out var expiresAt)) return false;
        if (expiresAt < DateTime.UtcNow)
        {
            // Expired entries can no longer affect any valid token; drop them.
            _entries.TryRemove(jti, out _);
            return false;
        }
        return true;
    }

    private void PruneExpired()
    {
        var now = DateTime.UtcNow;
        foreach (var kv in _entries)
        {
            if (kv.Value < now)
                _entries.TryRemove(kv.Key, out _);
        }
    }
}
