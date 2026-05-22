using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

/// <summary>A seller work session — see <c>MarketSystem.Domain.Entities.Shift</c>.</summary>
public record ShiftDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("openedAt")] DateTime OpenedAt,
    [property: JsonPropertyName("closedAt")] DateTime? ClosedAt,
    [property: JsonPropertyName("isOpen")] bool IsOpen,
    [property: JsonPropertyName("durationMinutes")] int DurationMinutes
);
