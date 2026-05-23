namespace MarketSystem.Domain.Exceptions;

/// <summary>
/// Thrown when a login is refused because the username has accumulated too
/// many failed attempts in the recent window. The global exception handler
/// maps this to HTTP 429 (Too Many Requests) with a structured body so the
/// client can surface a "try again in N minutes" message instead of a generic
/// "invalid credentials".
///
/// The lockout is per-username, not per-IP — it catches the case where an
/// attacker rotates IPs to defeat the request-rate limiter. The IP-based
/// limiter and this username-based lockout are complementary defences.
/// </summary>
public class LoginLockedException : Exception
{
    public string Username { get; }
    public DateTime LockedUntilUtc { get; }
    public int FailureCount { get; }

    public LoginLockedException(string username, DateTime lockedUntilUtc, int failureCount)
        : base($"Account '{username}' is locked until {lockedUntilUtc:O} after {failureCount} failed attempts.")
    {
        Username = username;
        LockedUntilUtc = lockedUntilUtc;
        FailureCount = failureCount;
    }
}
