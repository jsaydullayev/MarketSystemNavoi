namespace MarketSystem.Domain.Enums;

/// <summary>
/// A seller's work-shift state. Controlled by Admin/Owner; defaults to
/// <see cref="Active"/> so existing users are unaffected by the feature.
/// </summary>
public enum ShiftStatus
{
    /// <summary>Shift is on indefinitely — the seller can work with no time limit.</summary>
    Active = 0,

    /// <summary>Shift is off — the seller is blocked from logging in.</summary>
    Blocked = 1,

    /// <summary>Shift is on only inside the [ShiftStartUtc, ShiftEndUtc] window.</summary>
    Scheduled = 2,
}
