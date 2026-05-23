using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Manages seller work sessions (<c>Shift</c>). Each user has at most one open
/// shift at a time; all operations are scoped to the current market.
/// </summary>
public interface IShiftService
{
    /// <summary>The user's currently open shift, or null when none is open.</summary>
    Task<ShiftDto?> GetCurrentShiftAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>Opens a work shift for the user. Idempotent — if a shift is
    /// already open it is returned unchanged.</summary>
    Task<ShiftDto> OpenShiftAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>Closes the user's open shift. Throws
    /// <see cref="InvalidOperationException"/> when no shift is open.</summary>
    Task<ShiftDto> CloseShiftAsync(Guid userId, CancellationToken cancellationToken = default);
}
