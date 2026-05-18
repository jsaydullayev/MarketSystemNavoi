namespace MarketSystem.Application.DTOs;

/// <summary>
/// Top-N product ranking for the dashboard "Best sellers" card and the
/// Reports → Top Products page.
/// </summary>
/// <param name="Period">Echo of the requested period ("today" | "week" | "month" | "year").</param>
/// <param name="SortBy">Echo of the requested sort key ("quantity" | "revenue" | "profit").</param>
/// <param name="Items">Rows ordered by the chosen sort key, descending. Rank assigned 1-based.</param>
public record TopProductsDto(
    string Period,
    string SortBy,
    List<TopProductRow> Items);

/// <summary>
/// One row in the top-products ranking.
/// </summary>
/// <param name="Rank">1-based rank within the response.</param>
/// <param name="ProductId">Product identifier (Guid as string for cross-platform clients).</param>
/// <param name="Name">Display name at the time of query.</param>
/// <param name="Category">Category name, or empty string if uncategorized.</param>
/// <param name="Sellers">Distinct seller count touching this product in the period.</param>
/// <param name="Quantity">Sum of <c>SaleItem.Quantity</c>. Decimal because Strotech allows
/// fractional units (1.5 kg, 0.75 L) — keeping it as int would silently floor those sales.</param>
/// <param name="Revenue">Sum of <c>SaleItem.SalePrice × Quantity</c>.</param>
/// <param name="Profit">Sum of <c>(SalePrice − effective CostPrice) × Quantity</c>; null when the caller is not allowed to see cost data.</param>
public record TopProductRow(
    int Rank,
    string ProductId,
    string Name,
    string Category,
    int Sellers,
    decimal Quantity,
    decimal Revenue,
    decimal? Profit);
