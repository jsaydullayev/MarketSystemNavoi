using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

/// <summary>
/// One row from the audit log, projected for the read API. <see cref="UserName"/>
/// comes from a LEFT JOIN to the User table and is null when the audit entry
/// has no actor (e.g. a failed-login attempt where the username didn't resolve)
/// or the actor has since been hard-deleted (FK switched to NULL).
/// </summary>
public record AuditLogDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("entityType")] string EntityType,
    [property: JsonPropertyName("entityId")] Guid EntityId,
    [property: JsonPropertyName("action")] string Action,
    [property: JsonPropertyName("userId")] Guid? UserId,
    [property: JsonPropertyName("userName")] string? UserName,
    [property: JsonPropertyName("payload")] string Payload,
    [property: JsonPropertyName("ipAddress")] string? IpAddress,
    [property: JsonPropertyName("marketId")] int? MarketId,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);

/// <summary>
/// Server-side filter for <c>GET /api/audit-logs</c>. All filter fields are
/// optional (null = no filter); paging defaults are applied by the service.
/// <see cref="MarketId"/> is set by the controller — Owner / Admin are forced
/// to their own tenant, SuperAdmin may pass any value (or null = all markets).
/// </summary>
public record AuditLogFilter(
    string? EntityType = null,
    string? Action = null,
    Guid? UserId = null,
    int? MarketId = null,
    DateTime? FromUtc = null,
    DateTime? ToUtc = null,
    int Page = 1,
    int Size = 50);
