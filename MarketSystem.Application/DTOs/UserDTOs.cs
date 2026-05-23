using System.Collections.Generic;
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
    [property: JsonPropertyName("marketId")] int? MarketId,
    // Work shift — "Active" / "Blocked" / "Scheduled"; window times are only
    // meaningful for "Scheduled". IsShiftActive is the computed effective state.
    [property: JsonPropertyName("shiftStatus")] string ShiftStatus,
    [property: JsonPropertyName("shiftStartUtc")] DateTime? ShiftStartUtc,
    [property: JsonPropertyName("shiftEndUtc")] DateTime? ShiftEndUtc,
    [property: JsonPropertyName("isShiftActive")] bool IsShiftActive,
    // Owner RBAC — the user's effective permission set (full catalogue for
    // Owner/SuperAdmin). Lets the client gate its UI without a second call.
    [property: JsonPropertyName("permissions")] IReadOnlyList<string> Permissions
);

/// <summary>
/// Owner-facing view of one user's permission configuration. Backs the
/// permission-matrix screen: <see cref="Catalog"/> renders every toggle,
/// <see cref="EffectivePermissions"/> marks the ones currently ON, and
/// <see cref="RoleDefaults"/> powers a "reset to role default" action.
/// </summary>
public record UserPermissionsDto(
    [property: JsonPropertyName("userId")] Guid UserId,
    [property: JsonPropertyName("role")] string Role,
    // True once the Owner has saved an explicit set; false while the user
    // still runs on the role default.
    [property: JsonPropertyName("isCustomized")] bool IsCustomized,
    [property: JsonPropertyName("effectivePermissions")] IReadOnlyList<string> EffectivePermissions,
    [property: JsonPropertyName("roleDefaults")] IReadOnlyList<string> RoleDefaults,
    [property: JsonPropertyName("catalog")] IReadOnlyList<string> Catalog
);

/// <summary>Owner request to overwrite a user's explicit permission set.</summary>
public record UpdatePermissionsDto(
    [property: JsonPropertyName("permissions")] List<string> Permissions
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

/// <summary>
/// Admin/Owner request to set a seller's work shift. <see cref="Status"/> is
/// "Active", "Blocked" or "Scheduled"; the window times are required only
/// when scheduling.
/// </summary>
public record UpdateShiftDto(
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("startUtc")] DateTime? StartUtc,
    [property: JsonPropertyName("endUtc")] DateTime? EndUtc
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
