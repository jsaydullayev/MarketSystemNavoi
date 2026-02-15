using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record CreateMarketRequest(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("subdomain")] string? Subdomain,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("adminFullName")] string AdminFullName,
    [property: JsonPropertyName("adminUsername")] string AdminUsername,
    [property: JsonPropertyName("adminPassword")] string AdminPassword,
    [property: JsonPropertyName("expiresAt")] DateTime? ExpiresAt = null
);

public record MarketDto(
    [property: JsonPropertyName("id")] int Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("subdomain")] string? Subdomain,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("expiresAt")] DateTime? ExpiresAt,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);
