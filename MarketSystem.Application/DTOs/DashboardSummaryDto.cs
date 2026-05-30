namespace MarketSystem.Application.DTOs;

/// <summary>
/// Pre-aggregated Owner-dashboard counters. Added so the client no longer has
/// to download three full catalogs (all customers, all products, all debts)
/// and aggregate them on the UI isolate — that synchronous decode + fold was a
/// measured jank source on the dashboard. Every value here is computed with a
/// single COUNT/SUM query scoped to the caller's market.
/// </summary>
/// <param name="CustomerCount">Non-deleted customers in the market (mirrors GetAllCustomers().length).</param>
/// <param name="LowStockCount">Products where Quantity ≤ MinThreshold (mirrors Product.IsLowStock).</param>
/// <param name="PendingDebtsCount">Debts with RemainingDebt &gt; 0.</param>
/// <param name="PendingDebtsTotal">Sum of RemainingDebt across pending debts.</param>
/// <param name="OverdueDebtsCount">Pending debts past their DueDate, or — when no DueDate is set — created more than 14 days ago.</param>
public record DashboardSummaryDto(
    int CustomerCount,
    int LowStockCount,
    int PendingDebtsCount,
    decimal PendingDebtsTotal,
    int OverdueDebtsCount);
