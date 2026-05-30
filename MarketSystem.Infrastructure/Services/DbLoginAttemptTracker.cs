using System.Collections.Concurrent;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Infrastructure.Services;

/// <summary>
/// M1 fix — durable brute-force lockout store.
///
/// The previous <see cref="MarketSystem.Application.Services.InMemoryLoginAttemptTracker"/>
/// kept the failure counter in a process-local ConcurrentDictionary, so any
/// API restart (redeploy, OOM kill, manual `docker compose restart`) wiped
/// the lockout state. An attacker who could trigger or wait for a restart
/// got a fresh batch of attempts. This implementation mirrors the
/// <c>DbRevokedTokenStore</c> design: a hot in-memory cache for O(1) reads
/// on every login attempt, with every <see cref="RecordFailureAsync"/> and
/// <see cref="RecordSuccessAsync"/> written through to PostgreSQL so the
/// counter and any active lock survive a restart.
///
/// Startup hydration (<see cref="LoadFromDbAsync"/>) loads still-relevant
/// rows back into the cache and drops fully-stale ones so the table doesn't
/// grow without bound.
///
/// Thresholds match the in-memory variant so the two implementations are
/// drop-in compatible:
///   • <see cref="Threshold"/> failures inside <see cref="Window"/> → lock
///   • lock holds for <see cref="LockDuration"/> from the threshold failure
///   • a successful login wipes the username's history immediately
/// </summary>
public sealed class DbLoginAttemptTracker : ILoginAttemptTracker
{
    private const int Threshold = 5;
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan LockDuration = TimeSpan.FromMinutes(15);

    private readonly ConcurrentDictionary<string, AttemptState> _cache = new();
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<DbLoginAttemptTracker> _logger;

    public DbLoginAttemptTracker(
        IServiceScopeFactory scopeFactory,
        ILogger<DbLoginAttemptTracker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    /// <summary>
    /// Hydrate the in-memory cache from the LoginAttempts table at startup.
    /// Rows that have aged out (lock expired AND window fully elapsed) are
    /// pruned in the same pass so the table stays small over time.
    /// </summary>
    public async Task LoadFromDbAsync(CancellationToken ct = default)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

            var now = DateTime.UtcNow;
            var staleCutoff = now - (Window + LockDuration);

            // Drop rows whose lock has expired AND whose window has fully
            // elapsed since the first failure. Anything still active stays.
            var stale = await db.LoginAttempts
                .Where(a => (a.LockedUntilUtc == null || a.LockedUntilUtc <= now)
                            && a.FirstFailureUtc < staleCutoff)
                .ToListAsync(ct);
            if (stale.Count > 0)
            {
                db.LoginAttempts.RemoveRange(stale);
                await db.SaveChangesAsync(ct);
            }

            var active = await db.LoginAttempts.ToListAsync(ct);
            foreach (var row in active)
            {
                _cache[row.Username] = new AttemptState(
                    row.FailureCount,
                    row.FirstFailureUtc,
                    row.LockedUntilUtc ?? default);
            }

            _logger.LogInformation(
                "LoginAttemptTracker: hydrated {Active} active entries, pruned {Stale}.",
                active.Count, stale.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "LoginAttemptTracker: failed to load from DB — starting with empty cache.");
        }
    }

    public DateTime? GetLockedUntilUtc(string username)
    {
        if (string.IsNullOrWhiteSpace(username)) return null;
        var key = NormalizeKey(username);
        if (!_cache.TryGetValue(key, out var state)) return null;

        var now = DateTime.UtcNow;
        if (state.LockedUntilUtc <= now)
        {
            // Lock expired — opportunistically drop fully-stale entries so
            // the cache doesn't accumulate forever. The DB row is cleaned
            // up by the next startup sweep; we don't burn a DB write here
            // on the hot path.
            if (now - state.FirstFailureUtc > Window + LockDuration)
                _cache.TryRemove(key, out _);
            return null;
        }
        return state.LockedUntilUtc;
    }

    public async Task<LoginFailureResult> RecordFailureAsync(
        string username, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(username))
            return new LoginFailureResult(0, null);

        var key = NormalizeKey(username);
        var now = DateTime.UtcNow;

        // Compute the next state from the cache first so the typical
        // success path (already-locked / still-counting) doesn't hit the DB
        // hot for read+write — we just write the new state through.
        var updated = _cache.AddOrUpdate(
            key,
            _ => new AttemptState(1, now, default),
            (_, existing) =>
            {
                if (now - existing.FirstFailureUtc > Window)
                    return new AttemptState(1, now, default);
                if (existing.LockedUntilUtc > now)
                    return existing with { FailureCount = existing.FailureCount + 1 };
                var newCount = existing.FailureCount + 1;
                if (newCount >= Threshold)
                {
                    return existing with
                    {
                        FailureCount = newCount,
                        LockedUntilUtc = now + LockDuration,
                    };
                }
                return existing with { FailureCount = newCount };
            });

        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

            var existing = await db.LoginAttempts
                .FirstOrDefaultAsync(a => a.Username == key, ct);
            if (existing is null)
            {
                db.LoginAttempts.Add(new LoginAttempt
                {
                    Username = key,
                    FailureCount = updated.FailureCount,
                    FirstFailureUtc = updated.FirstFailureUtc,
                    LockedUntilUtc = updated.LockedUntilUtc == default
                        ? null
                        : updated.LockedUntilUtc,
                    UpdatedAtUtc = now,
                });
            }
            else
            {
                existing.FailureCount = updated.FailureCount;
                existing.FirstFailureUtc = updated.FirstFailureUtc;
                existing.LockedUntilUtc = updated.LockedUntilUtc == default
                    ? null
                    : updated.LockedUntilUtc;
                existing.UpdatedAtUtc = now;
            }
            await db.SaveChangesAsync(ct);
        }
        catch (Exception ex)
        {
            // DB write failed — cache is still updated so the lockout
            // takes effect on this instance. The forensic loss is one
            // row's worth of state on next restart, which is preferable
            // to the auth flow throwing on an unrelated DB hiccup.
            _logger.LogError(ex,
                "LoginAttemptTracker: failed to persist failure for {User}.", key);
        }

        var justLocked = updated.LockedUntilUtc > now
            && updated.FailureCount == Threshold;
        return new LoginFailureResult(
            updated.FailureCount,
            justLocked ? updated.LockedUntilUtc : null);
    }

    public async Task RecordSuccessAsync(
        string username, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(username)) return;
        var key = NormalizeKey(username);
        _cache.TryRemove(key, out _);

        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();
            var existing = await db.LoginAttempts
                .FirstOrDefaultAsync(a => a.Username == key, ct);
            if (existing is not null)
            {
                db.LoginAttempts.Remove(existing);
                await db.SaveChangesAsync(ct);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "LoginAttemptTracker: failed to clear success row for {User}.", key);
        }
    }

    /// <summary>Match the casing rules the rest of the auth stack uses —
    /// usernames are stored / compared in lowercase elsewhere, so the
    /// tracker keys on the same shape.</summary>
    private static string NormalizeKey(string username) =>
        username.Trim().ToLowerInvariant();

    /// <summary>One bucket of state per tracked username.</summary>
    private readonly record struct AttemptState(
        int FailureCount,
        DateTime FirstFailureUtc,
        DateTime LockedUntilUtc);
}
