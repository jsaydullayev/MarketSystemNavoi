using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record LoginRequest(
    [property: JsonPropertyName("username")]
    [property: Required(ErrorMessage = "Username majburiy")]
    [property: StringLength(50, MinimumLength = 3, ErrorMessage = "Username 3-50 belgi bo'lishi kerak")]
    string Username,

    [property: JsonPropertyName("password")]
    [property: Required(ErrorMessage = "Parol majburiy")]
    [property: StringLength(100, MinimumLength = 6, ErrorMessage = "Parol kamida 6 belgi bo'lishi kerak")]
    string Password
) {
    public LoginRequest() : this(string.Empty, string.Empty) { }
}

public record RegisterRequest(
    [property: JsonPropertyName("fullName")]
    [property: Required(ErrorMessage = "To'liq ism majburiy")]
    [property: StringLength(100, MinimumLength = 2, ErrorMessage = "Ism 2-100 belgi bo'lishi kerak")]
    string FullName,

    [property: JsonPropertyName("username")]
    [property: Required(ErrorMessage = "Username majburiy")]
    [property: StringLength(50, MinimumLength = 3, ErrorMessage = "Username 3-50 belgi bo'lishi kerak")]
    string Username,

    [property: JsonPropertyName("password")]
    [property: Required(ErrorMessage = "Parol majburiy")]
    [property: StringLength(100, MinimumLength = 6, ErrorMessage = "Parol kamida 6 belgi bo'lishi kerak")]
    string Password,

    [property: JsonPropertyName("role")]
    [property: Required(ErrorMessage = "Rol majburiy")]
    string Role,

    [property: JsonPropertyName("marketId")] int? MarketId = null,
    [property: JsonPropertyName("marketName")]
    [property: StringLength(100, ErrorMessage = "Market nomi 100 belgidan oshmasligi kerak")]
    string? MarketName = null,
    [property: JsonPropertyName("language")] string? Language = "uz"
) {
    public RegisterRequest() : this(string.Empty, string.Empty, string.Empty, string.Empty) { }
}

public record RefreshTokenRequest(
    [property: JsonPropertyName("accessToken")]
    [property: Required(ErrorMessage = "Access token majburiy")]
    string AccessToken,

    [property: JsonPropertyName("refreshToken")]
    [property: Required(ErrorMessage = "Refresh token majburiy")]
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
    [property: JsonPropertyName("expiresAt")] DateTime ExpiresAt
) {
    public AuthResponse() : this(Guid.Empty, string.Empty, string.Empty, string.Empty, string.Empty, string.Empty, string.Empty, DateTime.MinValue) { }
}
