namespace MarketSystem.Application.DTOs;

/// <summary>
/// One seller's own statistics for the Seller dashboard. Includes today's
/// sale count, revenue, and a derived shift duration based on the timestamp
/// of the first non-draft sale of the day (we don't yet have a Shift entity,
/// so "shift started" is approximated by the first sale).
/// </summary>
/// <param name="Period">Echo of the requested period ("today" | "week" | "month").</param>
/// <param name="UserId">The seller's user id.</param>
/// <param name="FullName">Display name.</param>
/// <param name="SaleCount">Count of non-draft, non-cancelled sales in period.</param>
/// <param name="Revenue">Sum of <c>Sale.TotalAmount</c> for those sales.</param>
/// <param name="AverageCheck">Revenue / SaleCount, or 0 when SaleCount = 0.</param>
/// <param name="FirstSaleAtUtc">Timestamp of the seller's first sale of the
/// day, used to estimate "shift duration". Null when no sales today.</param>
/// <param name="ShiftDurationMinutes">Minutes elapsed since FirstSaleAtUtc,
/// or 0 when there's no sale today. Floor'd to int — UI converts to hours.</param>
public record MyPerformanceDto(
    string Period,
    string UserId,
    string FullName,
    int SaleCount,
    decimal Revenue,
    decimal AverageCheck,
    DateTime? FirstSaleAtUtc,
    int ShiftDurationMinutes);
