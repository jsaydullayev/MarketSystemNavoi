using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using MarketSystem.Application.Validation;

namespace MarketSystem.Application.DTOs;

public record LoginRequest(
    [property: JsonPropertyName("username")]
    [param: Required(ErrorMessage = "Username majburiy")]
    [param: StringLength(50, MinimumLength = 3, ErrorMessage = "Username 3-50 belgi bo'lishi kerak")]
    string Username,

    // Login DOES NOT enforce the strong-password rule — old accounts created
    // under the previous 6-char policy must still be able to log in. The
    // policy applies only to PASSWORD CREATION (Register / CreateUser /
    // UpdateUser / UpdateProfile).
    [property: JsonPropertyName("password")]
    [param: Required(ErrorMessage = "Parol majburiy")]
    [param: StringLength(100, MinimumLength = 1, ErrorMessage = "Parol majburiy")]
    string Password
) {
    public LoginRequest() : this(string.Empty, string.Empty) { }
}

public record RegisterRequest(
    [property: JsonPropertyName("fullName")]
    [param: Required(ErrorMessage = "To'liq ism majburiy")]
    [param: StringLength(100, MinimumLength = 2, ErrorMessage = "Ism 2-100 belgi bo'lishi kerak")]
    string FullName,

    [property: JsonPropertyName("username")]
    [param: Required(ErrorMessage = "Username majburiy")]
    [param: StringLength(50, MinimumLength = 3, ErrorMessage = "Username 3-50 belgi bo'lishi kerak")]
    string Username,

    [property: JsonPropertyName("password")]
    [param: Required(ErrorMessage = "Parol majburiy")]
    [param: StrongPassword]
    string Password,

    [property: JsonPropertyName("role")]
    [param: Required(ErrorMessage = "Rol majburiy")]
    string Role,

    [property: JsonPropertyName("marketId")] int? MarketId = null,
    [property: JsonPropertyName("marketName")]
    [param: StringLength(100, ErrorMessage = "Market nomi 100 belgidan oshmasligi kerak")]
    string? MarketName = null,
    [property: JsonPropertyName("language")] string? Language = "uz"
) {
    public RegisterRequest() : this(string.Empty, string.Empty, string.Empty, string.Empty) { }
}

public record RefreshTokenRequest(
    [property: JsonPropertyName("accessToken")]
    [param: Required(ErrorMessage = "Access token majburiy")]
    string AccessToken,

    [property: JsonPropertyName("refreshToken")]
    [param: Required(ErrorMessage = "Refresh token majburiy")]
    string RefreshToken
) {
    public RefreshTokenRequest() : this(string.Empty, string.Empty) { }
}

public record AuthResponse(
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("language")] string Language,
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken,
    [property: JsonPropertyName("expiresAt")] DateTime ExpiresAt,
    // Owner RBAC — the user's effective permission set, so the client can
    // gate its UI. Owner/SuperAdmin receive the full catalogue.
    [property: JsonPropertyName("permissions")] IReadOnlyList<string> Permissions
) {
    public AuthResponse() : this(Guid.Empty, string.Empty, string.Empty, string.Empty, string.Empty, string.Empty, string.Empty, DateTime.MinValue, new List<string>()) { }
}
