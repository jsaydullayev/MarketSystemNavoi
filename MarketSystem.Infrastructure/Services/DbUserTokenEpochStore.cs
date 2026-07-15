using System.Collections.Concurrent;
using MarketSystem.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Infrastructure.Services;

/// <summary>
/// In-memory token-epoch cache (see <see cref="IUserTokenEpochStore"/>).
///
/// GetEpoch: pure ConcurrentDictionary lookup — O(1), on the auth hot path, no DB hit.
/// Publish:  cache-only. The durable write lives in <c>UserService</c>, inside the same
///           transaction as the password / IsActive / role / permission change.
/// Startup:  hydrated from Users.TokensInvalidBeforeUtc (a tiny set — only users whose
///           credentials ever changed).
/// </summary>
public sealed class DbUserTokenEpochStore : IUserTokenEpochStore
{
    private readonly ConcurrentDictionary<Guid, DateTime> _cache = new();
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<DbUserTokenEpochStore> _logger;

    public DbUserTokenEpochStore(IServiceScopeFactory scopeFactory, ILogger<DbUserTokenEpochStore> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    /// <summary>
    /// Hydrate the cache at startup. FAIL-CLOSED: an exception here propagates and stops
    /// the app.
    ///
    /// Swallowing it (the previous behaviour) would leave the cache empty for the whole
    /// life of the process, which silently turns the epoch check into a no-op — every
    /// fired employee's and every password-changed user's access token would come back to
    /// life until the next restart. A security cache we could not build must never
    /// degrade quietly into "allow everything". Migrations have already run (with retries)
    /// by the time this is called, so a failure here means the DB is genuinely broken.
    /// </summary>
    public async Task LoadFromDbAsync(CancellationToken ct = default)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

            // IgnoreQueryFilters — soft-deleted users are precisely the ones whose
            // tokens must stay dead; the global IsDeleted filter would hide them and
            // silently resurrect a fired employee's access token after a restart.
            var entries = await db.Users
                .IgnoreQueryFilters()
                .Where(u => u.TokensInvalidBeforeUtc != null)
                .Select(u => new { u.Id, u.TokensInvalidBeforeUtc })
                .ToListAsync(ct);

            foreach (var e in entries)
                _cache[e.Id] = e.TokensInvalidBeforeUtc!.Value;

            _logger.LogInformation("UserTokenEpochStore: loaded {Count} stamped users from DB", entries.Count);
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex,
                "UserTokenEpochStore: FAILED to hydrate the token-epoch cache. Refusing to start — " +
                "serving requests with an empty cache would silently revive revoked access tokens.");
            throw;
        }
    }

    /// <summary>Cache-only. Never moves an epoch backwards.</summary>
    public void Publish(Guid userId, DateTime utcNow)
    {
        if (userId == Guid.Empty) return;
        _cache.AddOrUpdate(userId, utcNow, (_, existing) => existing > utcNow ? existing : utcNow);
    }

    public DateTime? GetEpoch(Guid userId)
        => _cache.TryGetValue(userId, out var epoch) ? epoch : null;
}
