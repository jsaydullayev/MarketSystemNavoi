using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record UserDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("profileImage")] string? ProfileImage,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("language")] string Language,
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("marketId")] int? MarketId
);

public record CreateUserDto(
    [property: JsonPropertyName("fullName")]
    [property: Required(ErrorMessage = "To'liq ism majburiy")]
    [property: StringLength(100, MinimumLength = 2)]
    string FullName,

    [property: JsonPropertyName("username")]
    [property: Required(ErrorMessage = "Username majburiy")]
    [property: StringLength(50, MinimumLength = 3)]
    string Username,

    [property: JsonPropertyName("password")]
    [property: Required(ErrorMessage = "Parol majburiy")]
    [property: StringLength(100, MinimumLength = 6)]
    string Password,

    [property: JsonPropertyName("role")]
    [property: Required(ErrorMessage = "Rol majburiy")]
    string Role,

    [property: JsonPropertyName("language")] string? Language = "uz"
);

public record UpdateUserDto(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("fullName")]
    [property: Required(ErrorMessage = "To'liq ism majburiy")]
    [property: StringLength(100, MinimumLength = 2)]
    string FullName,

    [property: JsonPropertyName("password")]
    [property: StringLength(100, MinimumLength = 6, ErrorMessage = "Parol kamida 6 belgi bo'lishi kerak")]
    string? Password,

    [property: JsonPropertyName("role")]
    [property: Required(ErrorMessage = "Rol majburiy")]
    string Role,

    [property: JsonPropertyName("isActive")] bool IsActive
);

public record UpdateProfileDto(
    [property: JsonPropertyName("fullName")]
    [property: StringLength(100, MinimumLength = 2)]
    string? FullName,

    [property: JsonPropertyName("currentPassword")]
    [property: StringLength(100, MinimumLength = 6)]
    string? CurrentPassword,

    [property: JsonPropertyName("newPassword")]
    [property: StringLength(100, MinimumLength = 6)]
    string? NewPassword
);

public record UpdateProfileImageDto(
    [property: JsonPropertyName("profileImage")]
    [property: Required(ErrorMessage = "Rasm majburiy")]
    string ProfileImage
);
