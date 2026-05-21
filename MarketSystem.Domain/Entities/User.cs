using MarketSystem.Domain.Common;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

public class User : BaseEntity, ISoftDelete
{
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    /// <summary>
    /// Contact phone — populated when an Owner is created from a
    /// <see cref="RegistrationRequest"/>; optional for users created any other way.
    /// </summary>
    public string? Phone { get; set; }
    /// <summary>
    /// Base64 encoded profile image data
    /// </summary>
    public string? ProfileImage { get; set; }
    public Role Role { get; set; }
    public Language Language { get; set; } = Language.Uzbek;
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; } = false;

    // --- Work shift — set by Admin/Owner, enforced at login for Sellers ---
    public ShiftStatus ShiftStatus { get; set; } = ShiftStatus.Active;
    public DateTime? ShiftStartUtc { get; set; }
    public DateTime? ShiftEndUtc { get; set; }

    /// <summary>
    /// True when the user may currently work: Active always, Scheduled only
    /// inside its [start, end] window, Blocked never.
    /// </summary>
    public bool IsShiftActiveNow()
        => ShiftStatus switch
        {
            ShiftStatus.Active => true,
            ShiftStatus.Blocked => false,
            ShiftStatus.Scheduled =>
                ShiftStartUtc is not null && ShiftEndUtc is not null
                && DateTime.UtcNow >= ShiftStartUtc.Value
                && DateTime.UtcNow <= ShiftEndUtc.Value,
            _ => true,
        };

    // --- Owner RBAC — fine-grained permissions ---
    /// <summary>
    /// Explicit per-user permission set, customised by the Owner. Stored as a
    /// PostgreSQL <c>text[]</c>. An EMPTY list means "not customised" — the
    /// user then falls back to <see cref="PermissionDefaults"/> for its role,
    /// so existing rows need no data migration. Ignored for Owner/SuperAdmin.
    /// </summary>
    public List<string> Permissions { get; set; } = new();

    /// <summary>
    /// The permissions actually in force for this user: the full catalogue for
    /// Owner/SuperAdmin, the explicit set when customised, otherwise the role
    /// default.
    /// </summary>
    public IReadOnlyList<string> GetEffectivePermissions()
    {
        if (Role is Role.Owner or Role.SuperAdmin)
            return PermissionKeys.All;
        return Permissions.Count > 0 ? Permissions : PermissionDefaults.ForRole(Role);
    }

    /// <summary>True when the user is allowed the given permission key. Owner
    /// and SuperAdmin always pass; everyone else is checked against their
    /// effective set.</summary>
    public bool HasPermission(string key)
    {
        if (Role is Role.Owner or Role.SuperAdmin)
            return true;
        return GetEffectivePermissions().Contains(key);
    }

    // Multi-tenancy
    public int? MarketId { get; set; }
    public Market? Market { get; set; }

    // Navigation properties
    public ICollection<Sale> Sales { get; set; } = new List<Sale>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
    public ICollection<Product> TemporaryProducts { get; set; } = new List<Product>();
}
