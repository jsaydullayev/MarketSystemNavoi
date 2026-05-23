namespace MarketSystem.Domain.Exceptions;

/// <summary>
/// Thrown when an operation that requires an OPEN shift is attempted while
/// the seller has no shift open — e.g. closing a shift that was never opened,
/// or a future caller that gates POS actions on shift state.
///
/// Distinct from generic <see cref="InvalidOperationException"/> so the
/// global exception handler can map it to HTTP 409 Conflict with a
/// structured body — the client uses the <c>code</c> to render a "Smenani
/// oching" prompt instead of a generic 400.
/// </summary>
public class ShiftNotOpenException : Exception
{
    public Guid UserId { get; }

    public ShiftNotOpenException(Guid userId)
        : base($"User '{userId}' has no open shift.")
    {
        UserId = userId;
    }
}
