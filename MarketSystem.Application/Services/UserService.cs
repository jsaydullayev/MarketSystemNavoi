using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;

    public UserService(IUnitOfWork unitOfWork, IAppDbContext context, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _context = context;
        _currentMarketService = currentMarketService;
    }

    public async Task<UserDto?> GetUserByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        // TryGetCurrentMarketId returns null for SuperAdmin (cross-tenant, no MarketId
        // in JWT). For regular tenant users it returns the scoped market id. EF Core
        // translates `u.MarketId == null` to `WHERE MarketId IS NULL`, which correctly
        // matches the SuperAdmin row in the database.
        var marketId = _currentMarketService.TryGetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        return MapToDto(user);
    }

    public async Task<UserDto?> GetUserByUsernameAsync(string username, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Username == username && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        return MapToDto(user);
    }

    public async Task<IEnumerable<UserDto>> GetAllUsersAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.MarketId == marketId,
            cancellationToken);

        return users.Select(MapToDto);
    }

    public async Task<UserDto> CreateUserAsync(CreateUserDto request, CancellationToken cancellationToken = default)
    {
        if (!Enum.TryParse<Role>(request.Role, ignoreCase: true, out var role))
            throw new InvalidOperationException($"Invalid role: '{request.Role}'");

        // Only Admin and Seller can be created through this endpoint.
        // Owner is created via self-registration; SuperAdmin is provisioned out-of-band.
        if (role is not (Role.Admin or Role.Seller))
            throw new InvalidOperationException("Faqat Admin yoki Seller foydalanuvchi yaratish mumkin.");

        var currentMarketId = _currentMarketService.TryGetCurrentMarketId();
        if (!currentMarketId.HasValue)
            throw new InvalidOperationException("Market topilmadi. Iltimos, qaytadan tizimga kiring.");

        // M3 — username uniqueness is enforced PER MARKET via the partial
        // unique index "IX_Users_MarketId_Username_Unique" (see AppDbContext).
        // The previous check was global, which would reject "ahmad" in
        // market B just because some other tenant already had an "ahmad".
        // Scope the precheck so it matches the DB constraint shape.
        if (await _unitOfWork.Users.AnyAsync(
                u => u.Username == request.Username && u.MarketId == currentMarketId,
                cancellationToken))
            throw new InvalidOperationException($"Username '{request.Username}' already exists");

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = request.FullName,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = role,
            Language = Enum.TryParse<Language>(request.Language, ignoreCase: true, out var lang)
                ? lang
                : Language.Uzbek,
            IsActive = true,
            MarketId = currentMarketId.Value
        };

        await _unitOfWork.Users.AddAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<UserDto?> UpdateUserAsync(UpdateUserDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == request.Id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        // Privilege-escalation guard. Without this, an Admin (who holds
        // users.manage by default) could PUT {"role":"Owner"} to promote
        // itself — or rewrite the real Owner row — and bypass all RBAC.
        // Mirror CreateUserAsync: an Owner/SuperAdmin is never editable here,
        // and the only assignable roles are Admin and Seller.
        if (user.Role is Role.Owner or Role.SuperAdmin)
            return null;

        if (!Enum.TryParse<Role>(request.Role, ignoreCase: true, out var newRole))
            throw new InvalidOperationException($"Invalid role: '{request.Role}'");
        if (newRole is not (Role.Admin or Role.Seller))
            throw new InvalidOperationException("Faqat Admin yoki Seller rolini belgilash mumkin.");

        user.FullName = request.FullName;
        user.Role = newRole;
        user.IsActive = request.IsActive;

        // Update password only if provided
        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
        }

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<UserDto?> UpdateProfileAsync(Guid userId, UpdateProfileDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == userId && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        // Update full name if provided
        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName;
        }

        // Update password if both current and new password are provided
        if (!string.IsNullOrWhiteSpace(request.CurrentPassword) &&
            !string.IsNullOrWhiteSpace(request.NewPassword))
        {
            // Verify current password
            if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                throw new UnauthorizedAccessException("Current password is incorrect");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        }

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<UserDto?> UpdateProfileImageAsync(Guid userId, UpdateProfileImageDto request, CancellationToken cancellationToken = default)
    {
        // S3 — scope the user lookup to the caller's current market. The old
        // code trusted "the userId comes from the JWT, that's enough" — true
        // for the request body, but every other UserService method also
        // verifies the looked-up user lives in the caller's market. A token
        // replayed onto the wrong subdomain (e.g. a stolen Owner-A token
        // hitting tenant-B's host) would otherwise still let the attacker
        // mutate their OWN profile image while running under tenant B's
        // context. SuperAdmin (MarketId NULL) keeps working: we use
        // TryGetCurrentMarketId so the null case matches user.MarketId IS NULL.
        var currentMarketId = _currentMarketService.TryGetCurrentMarketId();
        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == userId && u.MarketId == currentMarketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        // Validate base64 image size (approximately)
        if (!string.IsNullOrEmpty(request.ProfileImage))
        {
            // Remove data URL prefix if present
            var base64Data = request.ProfileImage;
            if (base64Data.StartsWith("data:image/"))
            {
                var commaIndex = base64Data.IndexOf(',');
                if (commaIndex > 0)
                {
                    base64Data = base64Data.Substring(commaIndex + 1);
                }
            }

            // Check base64 string length (10MB limit in base64 is approximately 13M characters)
            if (base64Data.Length > 13_000_000)
            {
                throw new ArgumentException("Rasm hajmi juda katta. Maksimum rasm hajmi 10MB.");
            }

            // Validate base64 format
            try
            {
                Convert.FromBase64String(base64Data);
            }
            catch (FormatException)
            {
                throw new ArgumentException("Rasm formati noto'g'ri.");
            }
        }

        user.ProfileImage = request.ProfileImage;

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<bool> DeleteUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return false;

        // Defence in depth: neither a SuperAdmin nor an Owner may be removed
        // through the regular Users endpoint.
        //  • SuperAdmin is cross-tenant (MarketId=null) so the filter above
        //    already excludes them; the guard stays as belt-and-braces.
        //  • Owner is the market's top-level account. An Admin (who also holds
        //    UsersManage) is in the same tenant and would otherwise pass the
        //    marketId filter and delete their own Owner — a privilege
        //    escalation. The Owner lifecycle is owned by the SuperAdmin console
        //    (SuperAdminController), never by an in-market Admin.
        if (user.Role is Role.SuperAdmin or Role.Owner)
            return false;

        // Soft-delete — mirrors the SuperAdmin owner-delete flow and preserves
        // audit history. A hard delete would either fail (FK RESTRICT against
        // AuditLogs.UserId, per Plan 07 Bosqich 5) or rewrite history if we
        // ever relaxed the FK — soft-delete sidesteps both. The user becomes
        // hidden by the global IsDeleted query filter.
        user.IsActive = false;
        user.IsDeleted = true;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeactivateUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return false;

        // An Admin must never deactivate the market's Owner (or a SuperAdmin).
        // Owner lifecycle belongs to the SuperAdmin console only.
        if (user.Role is Role.SuperAdmin or Role.Owner)
            return false;

        user.IsActive = false;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> ActivateUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return false;

        // Symmetric with deactivate/delete: an Admin can't flip an Owner's
        // (or SuperAdmin's) active state. Owner lifecycle = SuperAdmin console.
        if (user.Role is Role.SuperAdmin or Role.Owner)
            return false;

        user.IsActive = true;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<UserDto?> UpdateShiftAsync(Guid id, UpdateShiftDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        if (!Enum.TryParse<ShiftStatus>(request.Status, ignoreCase: true, out var status))
            throw new InvalidOperationException($"Noto'g'ri smena holati: '{request.Status}'");

        if (status == ShiftStatus.Scheduled)
        {
            if (request.StartUtc is null || request.EndUtc is null)
                throw new InvalidOperationException("Rejalashtirilgan smena uchun boshlanish va tugash vaqti kerak.");
            if (request.EndUtc <= request.StartUtc)
                throw new InvalidOperationException("Smena tugash vaqti boshlanish vaqtidan keyin bo'lishi kerak.");

            user.ShiftStatus = ShiftStatus.Scheduled;
            user.ShiftStartUtc = DateTime.SpecifyKind(request.StartUtc.Value, DateTimeKind.Utc);
            user.ShiftEndUtc = DateTime.SpecifyKind(request.EndUtc.Value, DateTimeKind.Utc);
        }
        else
        {
            // Active / Blocked clear the window so stale times never linger.
            user.ShiftStatus = status;
            user.ShiftStartUtc = null;
            user.ShiftEndUtc = null;
        }

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    /// <summary>
    /// Owner-only: read a user's permission configuration for the
    /// permission-matrix screen. Scoped to the caller's market.
    /// </summary>
    public async Task<UserPermissionsDto?> GetUserPermissionsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        return user is null ? null : BuildPermissionsDto(user);
    }

    /// <summary>
    /// Owner-only: overwrite a user's explicit permission set. An empty list
    /// resets the user to its role default. Owner/SuperAdmin are not editable.
    /// The change takes effect on the user's next login or token refresh.
    /// </summary>
    public async Task<UserPermissionsDto?> UpdateUserPermissionsAsync(Guid id, UpdatePermissionsDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
            return null;

        // Owner/SuperAdmin always have full access — their set is not configurable.
        if (user.Role is Role.Owner or Role.SuperAdmin)
            throw new InvalidOperationException("Owner va SuperAdmin ruxsatlari sozlanmaydi.");

        var requested = request.Permissions ?? new List<string>();

        // Reject unknown keys so a typo or tampered payload can't persist junk.
        var invalid = requested.Where(k => !PermissionKeys.IsValid(k)).Distinct().ToList();
        if (invalid.Count > 0)
            throw new InvalidOperationException($"Noma'lum ruxsat kaliti: {string.Join(", ", invalid)}");

        // Persist a deduplicated, catalogue-ordered set.
        var ordered = PermissionKeys.All.Where(requested.Contains).ToList();
        user.Permissions = ordered;

        // If the requested set exactly matches the role default, treat this as
        // a "reset" — clear the customisation flag so the user inherits future
        // default changes automatically. Any other explicit set (including
        // intentionally empty) marks the user as customised.
        // SetEquals is order-independent — safe even if PermissionKeys.All order changes.
        var roleDefault = PermissionDefaults.ForRole(user.Role);
        user.IsPermissionsCustomized = !ordered.ToHashSet().SetEquals(roleDefault);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return BuildPermissionsDto(user);
    }

    private static UserPermissionsDto BuildPermissionsDto(User user) => new(
        user.Id,
        user.Role.ToString(),
        user.IsPermissionsCustomized,
        user.GetEffectivePermissions(),
        PermissionDefaults.ForRole(user.Role),
        PermissionKeys.All
    );

    private static UserDto MapToDto(User user)
    {
        return new UserDto(
            user.Id,
            user.FullName,
            user.Username,
            user.ProfileImage,
            user.Role.ToString(),
            user.Language.ToString().ToLowerInvariant(),
            user.IsActive,
            user.MarketId,
            user.ShiftStatus.ToString(),
            user.ShiftStartUtc,
            user.ShiftEndUtc,
            user.IsShiftActiveNow(),
            user.GetEffectivePermissions()
        );
    }
}
