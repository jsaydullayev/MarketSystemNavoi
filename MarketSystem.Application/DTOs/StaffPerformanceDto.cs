namespace MarketSystem.Application.DTOs;

/// <summary>
/// Per-staff sales metrics for the Users list and the Reports → Staff page.
/// Includes staff with zero sales in the period so the page can show the
/// whole team, not just the active sellers.
/// </summary>
/// <param name="Period">Echo of the requested period ("today" | "week" | "month").</param>
/// <param name="Staff">Rows sorted by Revenue desc, then by FullName asc.</param>
public record StaffPerformanceDto(
    string Period,
    List<StaffRow> Staff);

/// <summary>
/// One staff member's performance row.
/// </summary>
/// <param name="Rank">1-based rank by Revenue. Zero-sales staff share the trailing ranks.</param>
/// <param name="UserId">User identifier (Guid as string).</param>
/// <param name="FullName">Display name.</param>
/// <param name="Role">"Owner" | "Admin" | "Seller".</param>
/// <param name="SaleCount">Distinct sales count attributed to this seller.</param>
/// <param name="Revenue">Sum of <c>Sale.TotalAmount</c>.</param>
/// <param name="AverageCheck">Revenue / SaleCount, or 0 when SaleCount = 0.</param>
/// <param name="ShiftCount">Distinct <c>Shift</c> sessions this user opened inside the period.</param>
/// <param name="IsActiveShift">True when the user currently has an open shift — even if it opened before the period started.</param>
public record StaffRow(
    int Rank,
    string UserId,
    string FullName,
    string Role,
    int SaleCount,
    decimal Revenue,
    decimal AverageCheck,
    int ShiftCount,
    bool IsActiveShift);
