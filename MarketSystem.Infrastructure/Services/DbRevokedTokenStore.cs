using System.Collections.Concurrent;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Infrastructure.Services;

/// <summary>
/// Hybrid revocation store: in-memory ConcurrentDictionary for O(1) hot-path
/// IsRevoked() checks, PostgreSQL for durability across restarts and replicas.
///
/// Startup: loads all non-expired entries from DB into memory.
/// Revoke:  writes to DB first (durable), then updates the memory cache.
/// IsRevoked: pure in-memory — no DB hit per request.
/// </summary>
public sealed class DbRevokedTokenStore : IRevokedTokenStore
{
    private readonly ConcurrentDictionary<string, DateTime> _cache = new();
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<DbRevokedTokenStore> _logger;

    public DbRevokedTokenStore(IServiceScopeFactory scopeFactory, ILogger<DbRevokedTokenStore> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    /// <summary>
    /// Called once at application startup to hydrate the in-memory cache from DB.
    /// </summary>
    public async Task LoadFromDbAsync(CancellationToken ct = default)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

            var now = DateTime.UtcNow;
            var entries = await db.RevokedTokens
                .Where(r => r.ExpiresAtUtc > now)
                .Select(r => new { r.Jti, r.ExpiresAtUtc })
                .ToListAsync(ct);

            foreach (var e in entries)
                _cache.TryAdd(e.Jti, e.ExpiresAtUtc);

            // Clean up expired entries from DB on startup
            var expired = await db.RevokedTokens
                .Where(r => r.ExpiresAtUtc <= now)
                .ToListAsync(ct);

            if (expired.Count > 0)
            {
                db.RevokedTokens.RemoveRange(expired);
                await db.SaveChangesAsync(ct);
            }

            _logger.LogInformation("RevokedTokenStore: loaded {Count} active entries from DB", entries.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RevokedTokenStore: failed to load from DB — falling back to empty cache");
        }
    }

    public async Task RevokeAsync(string jti, DateTime expiresAtUtc, CancellationToken ct = default)
    {
        if (string.IsNullOrEmpty(jti)) return;

        // Update memory immediately so the token is blocked on this instance now.
        _cache.AddOrUpdate(jti, expiresAtUtc, (_, existing) => existing > expiresAtUtc ? existing : expiresAtUtc);

        // Persist to DB so other instances and restarts see the revocation.
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

            var exists = await db.RevokedTokens.AnyAsync(r => r.Jti == jti, ct);
            if (!exists)
            {
                db.RevokedTokens.Add(new RevokedToken
                {
                    Jti = jti,
                    ExpiresAtUtc = expiresAtUtc,
                    RevokedAtUtc = DateTime.UtcNow
                });
                await db.SaveChangesAsync(ct);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RevokedTokenStore: failed to persist revocation for jti {Jti}", jti);
            // Memory cache is still updated — token is blocked on this instance.
        }
    }

    public bool IsRevoked(string jti)
    {
        if (string.IsNullOrEmpty(jti)) return false;
        if (!_cache.TryGetValue(jti, out var expiresAt)) return false;

        if (expiresAt < DateTime.UtcNow)
        {
            _cache.TryRemove(jti, out _);
            return false;
        }
        return true;
    }
}
