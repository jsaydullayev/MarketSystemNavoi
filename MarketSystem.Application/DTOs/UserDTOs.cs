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
    [param: Required(ErrorMessage = "To'liq ism majburiy")]
    [param: StringLength(100, MinimumLength = 2)]
    string FullName,

    [property: JsonPropertyName("username")]
    [param: Required(ErrorMessage = "Username majburiy")]
    [param: StringLength(50, MinimumLength = 3)]
    string Username,

    [property: JsonPropertyName("password")]
    [param: Required(ErrorMessage = "Parol majburiy")]
    [param: StringLength(100, MinimumLength = 6)]
    string Password,

    [property: JsonPropertyName("role")]
    [param: Required(ErrorMessage = "Rol majburiy")]
    string Role,

    [property: JsonPropertyName("language")] string? Language = "uz"
);

public record UpdateUserDto(
    [property: JsonPropertyName("id")] Guid Id,

    [property: JsonPropertyName("fullName")]
    [param: Required(ErrorMessage = "To'liq ism majburiy")]
    [param: StringLength(100, MinimumLength = 2)]
    string FullName,

    [property: JsonPropertyName("password")]
    [param: StringLength(100, MinimumLength = 6, ErrorMessage = "Parol kamida 6 belgi bo'lishi kerak")]
    string? Password,

    [property: JsonPropertyName("role")]
    [param: Required(ErrorMessage = "Rol majburiy")]
    string Role,

    [property: JsonPropertyName("isActive")] bool IsActive
);

public record UpdateProfileDto(
    [property: JsonPropertyName("fullName")]
    [param: StringLength(100, MinimumLength = 2)]
    string? FullName,

    [property: JsonPropertyName("currentPassword")]
    [param: StringLength(100, MinimumLength = 6)]
    string? CurrentPassword,

    [property: JsonPropertyName("newPassword")]
    [param: StringLength(100, MinimumLength = 6)]
    string? NewPassword
);

public record UpdateProfileImageDto(
    [property: JsonPropertyName("profileImage")]
    [param: Required(ErrorMessage = "Rasm majburiy")]
    string ProfileImage
);
