namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Tracks failed-login attempts per username so the auth flow can lock an
/// account out after too many failures in a short window. Pairs with the
/// IP-based rate limiter — the limiter stops one IP from probing fast, this
/// stops a distributed attacker from probing one username at a normal pace.
///
/// Implementations must be:
/// - Fast on <see cref="GetLockedUntilUtc"/> — called on every login attempt,
///   so it stays a synchronous in-memory check.
/// - Durable on <see cref="RecordFailureAsync"/> / <see cref="RecordSuccessAsync"/>
///   — persisted so the lockout survives process restarts (and propagates
///   across multiple replicas when we eventually scale out). The first M1
///   draft used pure in-memory state and could be reset by any restart;
///   <see cref="DbLoginAttemptTracker"/> closes that hole.
/// </summary>
public interface ILoginAttemptTracker
{
    /// <summary>
    /// If the username is currently locked, returns the UTC instant when the
    /// lock expires; otherwise null. Cheap to call on every login attempt —
    /// implementations keep the state in memory.
    /// </summary>
    DateTime? GetLockedUntilUtc(string username);

    /// <summary>
    /// Record a failed login. Returns the updated state so the caller can
    /// throw a "you just got locked" exception on the threshold-th failure
    /// (rather than letting the user discover the lock on their next try).
    /// </summary>
    Task<LoginFailureResult> RecordFailureAsync(string username, CancellationToken ct = default);

    /// <summary>
    /// Clear all failure history for the username. Called after a successful
    /// login so a user who got the password right after one typo isn't still
    /// counted as suspicious.
    /// </summary>
    Task RecordSuccessAsync(string username, CancellationToken ct = default);
}

/// <summary>
/// Snapshot returned by <see cref="ILoginAttemptTracker.RecordFailureAsync"/>.
/// </summary>
/// <param name="FailureCount">Total failures inside the current window.</param>
/// <param name="LockedUntilUtc">Non-null iff this failure just tripped the
/// lockout; the timestamp is when the lock expires.</param>
public record LoginFailureResult(int FailureCount, DateTime? LockedUntilUtc);
