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

/// <summary>
/// Aggregated "things that look bad" report for <c>GET /api/audit-logs/suspicious</c>
/// (Plan 07 Bosqich 3). Each list contains zero or more flagged groups; an
/// empty report means nothing currently trips the detection rules.
/// </summary>
public record SuspiciousActivityReport(
    [property: JsonPropertyName("failedLoginBursts")]
    IReadOnlyList<FailedLoginBurstDto> FailedLoginBursts,
    [property: JsonPropertyName("bulkDeleteBursts")]
    IReadOnlyList<BulkDeleteBurstDto> BulkDeleteBursts,
    // Recent server-side faults (5xx) captured by the global exception handler.
    // Surfaced so the Owner/developer can read the status code + message and fix
    // the problem without trawling server logs.
    [property: JsonPropertyName("recentErrors")]
    IReadOnlyList<ErrorEntryDto> RecentErrors
);

/// <summary>
/// One recorded server-side fault, projected for the "Suspicious" tab. The
/// fields are parsed out of the audit payload the exception handler wrote.
/// </summary>
public record ErrorEntryDto(
    [property: JsonPropertyName("statusCode")] int StatusCode,
    [property: JsonPropertyName("message")] string Message,
    [property: JsonPropertyName("path")] string? Path,
    [property: JsonPropertyName("method")] string? Method,
    [property: JsonPropertyName("userName")] string? UserName,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);

/// <summary>
/// One username that hit the failed-login threshold (5+ <c>LoginFailed</c>
/// events in the last 15 minutes). <see cref="IpAddresses"/> is the distinct
/// set of IPs we saw across the window — credential-stuffing from many IPs
/// against one account looks different from a single fat-fingered user.
/// </summary>
public record FailedLoginBurstDto(
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("count")] int Count,
    [property: JsonPropertyName("firstSeenUtc")] DateTime FirstSeenUtc,
    [property: JsonPropertyName("lastSeenUtc")] DateTime LastSeenUtc,
    [property: JsonPropertyName("ipAddresses")] IReadOnlyList<string> IpAddresses
);

/// <summary>
/// One user who issued 5+ <c>Delete</c> actions in the last 10 minutes.
/// <see cref="EntityTypes"/> shows what was deleted — "User, User, User" is
/// very different from "Sale, Sale, Sale" and the review screen colours them
/// accordingly.
/// </summary>
public record BulkDeleteBurstDto(
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("userName")] string? UserName,
    [property: JsonPropertyName("count")] int Count,
    [property: JsonPropertyName("firstSeenUtc")] DateTime FirstSeenUtc,
    [property: JsonPropertyName("lastSeenUtc")] DateTime LastSeenUtc,
    [property: JsonPropertyName("entityTypes")] IReadOnlyList<string> EntityTypes
);
