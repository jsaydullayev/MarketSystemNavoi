using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record LoginRequest(
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password
) {
    // Parameterless constructor for model binding
    public LoginRequest() : this(string.Empty, string.Empty) { }
}

public record RegisterRequest(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("marketId")] int? MarketId = null,  // Multi-tenancy - optional
    [property: JsonPropertyName("marketName")] string? MarketName = null,  // For Owner to create market during registration
    [property: JsonPropertyName("language")] string? Language = "uz"
) {
    // Parameterless constructor for model binding
    public RegisterRequest() : this(string.Empty, string.Empty, string.Empty, string.Empty) { }
}

public record RefreshTokenRequest(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken
) {
    // Parameterless constructor for model binding
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
    // Parameterless constructor for model binding
    public AuthResponse() : this(Guid.Empty, string.Empty, string.Empty, string.Empty, string.Empty, string.Empty, string.Empty, DateTime.MinValue) { }
}
