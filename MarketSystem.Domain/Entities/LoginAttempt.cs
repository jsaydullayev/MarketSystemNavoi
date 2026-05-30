namespace MarketSystem.Domain.Entities;

/// <summary>
/// Persisted brute-force lockout state, one row per username under suspicion.
/// Replaces the previous in-memory ConcurrentDictionary so the lockout survives
/// process restarts (M1: the old implementation could be bypassed by anything
/// that triggered an API restart — crash, redeploy, container OOM, …).
///
/// Loaded into <see cref="DbLoginAttemptTracker"/>'s in-memory cache at startup
/// so the hot-path <c>GetLockedUntilUtc</c> check stays an O(1) dictionary read;
/// writes (<c>RecordFailureAsync</c> / <c>RecordSuccessAsync</c>) propagate
/// straight to PostgreSQL so the next process restart picks up where this one
/// left off.
///
/// Rows are pruned at startup once their window+lock has fully expired — no
/// background sweeper, since the table stays small (one row per actively-
/// probed username, no row for the much larger set of normal users who never
/// fail a login).
/// </summary>
public class LoginAttempt
{
    public int Id { get; set; }

    /// <summary>Normalized (lowercase, trimmed) username key.</summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>Failures counted inside the active sliding window.</summary>
    public int FailureCount { get; set; }

    /// <summary>UTC instant of the first failure that opened the window.</summary>
    public DateTime FirstFailureUtc { get; set; }

    /// <summary>
    /// UTC instant the lock expires. Null while the username is below
    /// threshold; non-null once the threshold was tripped. Cleared on
    /// successful login.
    /// </summary>
    public DateTime? LockedUntilUtc { get; set; }

    /// <summary>
    /// Last write time. Used by the startup sweep to drop rows where the
    /// window has long since closed and there's no active lock.
    /// </summary>
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}
