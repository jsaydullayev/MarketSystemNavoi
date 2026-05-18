namespace MarketSystem.Application.DTOs;

/// <summary>
/// N-day revenue/profit time series for the dashboard chart.
/// Each <see cref="DailyPoint"/> represents one Tashkent calendar day, ordered
/// oldest-to-newest. Days with no sales are still returned with zeros so the
/// frontend can plot a continuous bar chart without gap-filling logic.
/// </summary>
/// <param name="Points">Ordered day points; length equals the requested day count.</param>
/// <param name="CurrentTotal">Sum of <c>Revenue</c> across <c>Points</c> — pre-computed so the frontend doesn't have to reduce the list.</param>
/// <param name="PreviousTotal">Sum of revenue for the equally-sized window immediately before <c>Points</c> (only when <c>?compare=true</c>; null otherwise). Used by the dashboard ChartCard footer to display a week-over-week delta.</param>
public record WeeklySeriesDto(
    List<DailyPoint> Points,
    decimal CurrentTotal,
    decimal? PreviousTotal);

/// <summary>
/// Aggregate metrics for one day in the series.
/// </summary>
/// <param name="Date">Start-of-day in UTC (Tashkent 00:00 → UTC 19:00 previous day).</param>
/// <param name="Revenue">Sum of <c>Sale.TotalAmount</c> for sales in Paid/Debt/Closed status.</param>
/// <param name="Profit">Sum of <c>(SalePrice − effective CostPrice) × Quantity</c> across items. Zero for non-Owner callers.</param>
/// <param name="CheckCount">Number of distinct sales on this day.</param>
public record DailyPoint(
    DateTime Date,
    decimal Revenue,
    decimal Profit,
    int CheckCount);
