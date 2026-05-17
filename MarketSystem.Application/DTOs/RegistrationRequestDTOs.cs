using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

/// <summary>
/// Public submission — what an anonymous visitor sends from the sign-up form.
/// </summary>
public record SubmitRegistrationRequestDto(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("phone")] string Phone
)
{
    public SubmitRegistrationRequestDto() : this(string.Empty, string.Empty) { }
}

/// <summary>
/// What the SuperAdmin console lists. Sensitive linkage IDs (CreatedUserId,
/// CreatedMarketId) are included so the UI can deep-link to the resulting owner/market.
/// </summary>
public record RegistrationRequestDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("processedAt")] DateTime? ProcessedAt,
    [property: JsonPropertyName("processedByUserName")] string? ProcessedByUserName,
    [property: JsonPropertyName("createdUserId")] Guid? CreatedUserId,
    [property: JsonPropertyName("createdMarketId")] int? CreatedMarketId,
    [property: JsonPropertyName("rejectReason")] string? RejectReason
);

/// <summary>
/// SuperAdmin approves a request — provides credentials for the new Owner and
/// a name for their new Market. Owners can change their password after first login.
/// </summary>
public record ApproveRegistrationRequestDto(
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password,
    [property: JsonPropertyName("marketName")] string MarketName,
    [property: JsonPropertyName("subdomain")] string? Subdomain = null,
    [property: JsonPropertyName("language")] string? Language = "uz"
)
{
    public ApproveRegistrationRequestDto() : this(string.Empty, string.Empty, string.Empty) { }
}

/// <summary>
/// Returned after a successful approval — the SuperAdmin needs the credentials
/// so they can pass them to the new owner out-of-band (SMS / phone call).
/// The password is NOT stored or returned anywhere else.
/// </summary>
public record ApproveRegistrationResultDto(
    [property: JsonPropertyName("requestId")] Guid RequestId,
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("marketId")] int MarketId,
    [property: JsonPropertyName("marketName")] string MarketName
);

public record RejectRegistrationRequestDto(
    [property: JsonPropertyName("reason")] string Reason
)
{
    public RejectRegistrationRequestDto() : this(string.Empty) { }
}

/// <summary>
/// Real-time availability check result. Each field is non-null only when the
/// caller queried it (i.e. passed a non-empty value for that field). This lets
/// the UI light up indicators field-by-field without forcing a full payload
/// every keystroke.
/// </summary>
public record CheckAvailabilityResultDto(
    [property: JsonPropertyName("usernameAvailable")] bool? UsernameAvailable,
    [property: JsonPropertyName("marketNameAvailable")] bool? MarketNameAvailable,
    [property: JsonPropertyName("subdomainAvailable")] bool? SubdomainAvailable,
    [property: JsonPropertyName("suggestedSubdomain")] string? SuggestedSubdomain
);

/// <summary>
/// "Active owner" list shown alongside pending requests in the SuperAdmin page.
/// </summary>
public record OwnerSummaryDto(
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("phone")] string? Phone,
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("marketId")] int? MarketId,
    [property: JsonPropertyName("marketName")] string? MarketName,
    [property: JsonPropertyName("isMarketBlocked")] bool IsMarketBlocked,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);

/// <summary>
/// Full owner profile for the detail page — Owner identity, the Market it
/// belongs to, and live aggregates so the operator can size up a tenant at a
/// glance. Stats are best-effort counts; expensive sums are computed at query
/// time (not denormalised) because this endpoint is rarely hit.
/// </summary>
public record OwnerDetailDto(
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("phone")] string? Phone,
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("language")] string Language,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("market")] OwnerDetailMarketDto? Market,
    [property: JsonPropertyName("stats")] OwnerDetailStatsDto Stats
);

public record OwnerDetailMarketDto(
    [property: JsonPropertyName("id")] int Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("subdomain")] string? Subdomain,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("isBlocked")] bool IsBlocked,
    [property: JsonPropertyName("blockedAt")] DateTime? BlockedAt,
    [property: JsonPropertyName("blockedReason")] string? BlockedReason,
    [property: JsonPropertyName("expiresAt")] DateTime? ExpiresAt,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);

/// <summary>SuperAdmin blocks a market — typically for non-payment.</summary>
public record BlockMarketDto(
    [property: JsonPropertyName("reason")] string Reason
)
{
    public BlockMarketDto() : this(string.Empty) { }
}

/// <summary>Returned after a block/unblock so the UI can refresh its state.</summary>
public record MarketBlockStatusDto(
    [property: JsonPropertyName("marketId")] int MarketId,
    [property: JsonPropertyName("marketName")] string MarketName,
    [property: JsonPropertyName("isBlocked")] bool IsBlocked,
    [property: JsonPropertyName("blockedAt")] DateTime? BlockedAt,
    [property: JsonPropertyName("reason")] string? Reason
);

public record OwnerDetailStatsDto(
    [property: JsonPropertyName("productsCount")] int ProductsCount,
    [property: JsonPropertyName("salesCount")] int SalesCount,
    [property: JsonPropertyName("customersCount")] int CustomersCount,
    [property: JsonPropertyName("cashiersCount")] int CashiersCount,
    [property: JsonPropertyName("outstandingDebt")] decimal OutstandingDebt
);

/// <summary>
/// SuperAdmin manually creates an owner+market without a public registration
/// request. Used for off-channel signups (phone call, walk-in). Mirrors the
/// approve flow's payload but adds the applicant fields the request would
/// have provided.
/// </summary>
public record CreateOwnerDto(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password,
    [property: JsonPropertyName("marketName")] string MarketName,
    [property: JsonPropertyName("subdomain")] string? Subdomain = null,
    [property: JsonPropertyName("language")] string? Language = "uz"
)
{
    public CreateOwnerDto() : this(string.Empty, string.Empty, string.Empty, string.Empty, string.Empty) { }
}

/// <summary>
/// Editable fields on an existing owner+market. Username is intentionally
/// excluded — changing a username invalidates JWTs and audit links, so we
/// surface it as a separate operation. Password is also not here for the
/// same reason; use a dedicated reset endpoint.
/// </summary>
public record UpdateOwnerDto(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("phone")] string? Phone,
    [property: JsonPropertyName("language")] string? Language,
    [property: JsonPropertyName("marketName")] string MarketName,
    [property: JsonPropertyName("subdomain")] string? Subdomain,
    [property: JsonPropertyName("description")] string? Description,
    // Two independent flags — previously a single `isActive` controlled both,
    // which meant deactivating an owner also dragged the market down (and left
    // their cashiers reachable). Keep them separate so the UI can suspend an
    // owner without ripping the storefront, or vice versa.
    [property: JsonPropertyName("ownerActive")] bool? OwnerActive,
    [property: JsonPropertyName("marketActive")] bool? MarketActive,
    [property: JsonPropertyName("expiresAt")] DateTime? ExpiresAt
)
{
    public UpdateOwnerDto() : this(string.Empty, null, null, string.Empty, null, null, null, null, null) { }
}

/// <summary>
/// Soft-delete payload. The market name confirmation matches the destructive
/// dialog's "type the name to confirm" pattern; a mismatched value bounces
/// with a 400. Reason is mandatory and lands in the audit log.
/// </summary>
public record DeleteOwnerDto(
    [property: JsonPropertyName("confirmMarketName")] string ConfirmMarketName,
    [property: JsonPropertyName("reason")] string Reason
)
{
    public DeleteOwnerDto() : this(string.Empty, string.Empty) { }
}
