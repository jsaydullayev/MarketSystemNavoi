namespace MarketSystem.Domain.Exceptions;

/// <summary>
/// Thrown when a request would operate on a market that the SuperAdmin has
/// administratively blocked (typically for non-payment). The global exception
/// handler maps this to HTTP 423 Locked + a structured body so the client can
/// render a "contact admin" screen with the reason instead of a generic error.
/// </summary>
public class MarketBlockedException : Exception
{
    public int MarketId { get; }
    public string? Reason { get; }
    public DateTime? BlockedAt { get; }

    public MarketBlockedException(int marketId, string? reason, DateTime? blockedAt)
        : base($"Market {marketId} is blocked: {reason}")
    {
        MarketId = marketId;
        Reason = reason;
        BlockedAt = blockedAt;
    }
}
