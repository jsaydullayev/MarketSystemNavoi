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
/// SuperAdmin directly creates a new Owner + Market without an in-queue
/// registration request — used when an applicant signs up out-of-band
/// (phone call, in-person). Phone is optional here because the SuperAdmin
/// already has the contact channel; everything else mirrors approve.
/// </summary>
public record CreateOwnerDto(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password,
    [property: JsonPropertyName("marketName")] string MarketName,
    [property: JsonPropertyName("phone")] string? Phone = null,
    [property: JsonPropertyName("subdomain")] string? Subdomain = null,
    [property: JsonPropertyName("language")] string? Language = "uz"
)
{
    public CreateOwnerDto() : this(string.Empty, string.Empty, string.Empty, string.Empty) { }
}

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
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
);
