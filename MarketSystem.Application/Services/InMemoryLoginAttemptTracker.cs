using System.Collections.Concurrent;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.Application.Services;

/// <summary>
/// Process-local brute-force lockout tracker (Plan 05 Bosqich 3 — username
/// based). Singleton, ConcurrentDictionary-backed. Survives the lifetime of
/// one server process — short revocations resetting on restart are tolerable
/// because the IP-based rate limiter still gates the burst surface.
///
/// Tunables (all internal — these are the rule, not config):
///   • <see cref="Threshold"/> failures inside <see cref="Window"/> → lock
///   • lock holds for <see cref="LockDuration"/> from the threshold failure
///   • a successful login wipes the username's history immediately
///
/// Memory bound: only one entry per username, dropped lazily when a stale
/// entry is inspected after its lock expires.
/// </summary>
public sealed class InMemoryLoginAttemptTracker : ILoginAttemptTracker
{
    /// <summary>Failures inside <see cref="Window"/> before the account locks.</summary>
    private const int Threshold = 5;

    /// <summary>Sliding window for counting failures.</summary>
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(15);

    /// <summary>How long the account stays locked once the threshold trips.</summary>
    private static readonly TimeSpan LockDuration = TimeSpan.FromMinutes(15);

    private readonly ConcurrentDictionary<string, AttemptState> _entries = new();

    public DateTime? GetLockedUntilUtc(string username)
    {
        if (string.IsNullOrWhiteSpace(username)) return null;
        var key = NormalizeKey(username);
        if (!_entries.TryGetValue(key, out var state)) return null;

        var now = DateTime.UtcNow;
        if (state.LockedUntilUtc <= now)
        {
            // Lock expired — opportunistically drop fully-stale entries so
            // the dictionary doesn't accumulate forever. Anything still
            // inside the window stays so future failures keep counting.
            if (now - state.FirstFailureUtc > Window + LockDuration)
                _entries.TryRemove(key, out _);
            return null;
        }
        return state.LockedUntilUtc;
    }

    public LoginFailureResult RecordFailure(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
            return new LoginFailureResult(0, null);

        var key = NormalizeKey(username);
        var now = DateTime.UtcNow;

        var updated = _entries.AddOrUpdate(
            key,
            // First failure for this username.
            _ => new AttemptState(1, now, default),
            (_, existing) =>
            {
                // Window expired — start fresh.
                if (now - existing.FirstFailureUtc > Window)
                    return new AttemptState(1, now, default);

                // Already locked. Increment the count for forensics but do
                // NOT extend the lock — otherwise an attacker could hammer
                // the endpoint and keep a legitimate user permanently out.
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

        // Only surface the LockedUntilUtc on the failure that JUST tripped
        // the threshold — otherwise the caller would re-throw on every
        // failure inside the lock window.
        var justLocked = updated.LockedUntilUtc > now
            && updated.FailureCount == Threshold;
        return new LoginFailureResult(
            updated.FailureCount,
            justLocked ? updated.LockedUntilUtc : null);
    }

    public void RecordSuccess(string username)
    {
        if (string.IsNullOrWhiteSpace(username)) return;
        _entries.TryRemove(NormalizeKey(username), out _);
    }

    /// <summary>Match the casing rules the rest of the auth stack uses —
    /// usernames are stored / compared in lowercase elsewhere, so the
    /// tracker keys on the same shape.</summary>
    private static string NormalizeKey(string username) =>
        username.Trim().ToLowerInvariant();

    /// <summary>One bucket of state per tracked username.</summary>
    /// <param name="FailureCount">Failures inside the active window.</param>
    /// <param name="FirstFailureUtc">When the window started — used to roll
    /// the counter once <see cref="Window"/> elapses.</param>
    /// <param name="LockedUntilUtc">UTC instant the lock expires; default
    /// (<c>DateTime.MinValue</c>) when not locked.</param>
    private readonly record struct AttemptState(
        int FailureCount,
        DateTime FirstFailureUtc,
        DateTime LockedUntilUtc);
}
