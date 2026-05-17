using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

/// <summary>
/// Standard pagination envelope. Clients receive { items, page, size, total, totalPages }.
/// </summary>
public record PagedResult<T>(
    [property: JsonPropertyName("items")] IReadOnlyList<T> Items,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("size")] int Size,
    [property: JsonPropertyName("total")] int Total,
    [property: JsonPropertyName("totalPages")] int TotalPages)
{
    public static PagedResult<T> Empty(int page, int size) => new(Array.Empty<T>(), page, size, 0, 0);

    public static PagedResult<T> From(IReadOnlyList<T> items, int page, int size, int total)
    {
        var totalPages = size > 0 ? (int)Math.Ceiling(total / (double)size) : 0;
        return new PagedResult<T>(items, page, size, total, totalPages);
    }
}

public record PagedResponse<T>(
    [property: JsonPropertyName("items")] List<T> Items,
    [property: JsonPropertyName("totalCount")] int TotalCount,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("pageSize")] int PageSize
);
