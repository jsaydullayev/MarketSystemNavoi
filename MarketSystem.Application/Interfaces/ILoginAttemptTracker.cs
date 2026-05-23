namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Tracks failed-login attempts per username so the auth flow can lock an
/// account out after too many failures in a short window. Pairs with the
/// IP-based rate limiter — the limiter stops one IP from probing fast, this
/// stops a distributed attacker from probing one username at a normal pace.
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
    LoginFailureResult RecordFailure(string username);

    /// <summary>
    /// Clear all failure history for the username. Called after a successful
    /// login so a user who got the password right after one typo isn't still
    /// counted as suspicious.
    /// </summary>
    void RecordSuccess(string username);
}

/// <summary>
/// Snapshot returned by <see cref="ILoginAttemptTracker.RecordFailure"/>.
/// </summary>
/// <param name="FailureCount">Total failures inside the current window.</param>
/// <param name="LockedUntilUtc">Non-null iff this failure just tripped the
/// lockout; the timestamp is when the lock expires.</param>
public record LoginFailureResult(int FailureCount, DateTime? LockedUntilUtc);
