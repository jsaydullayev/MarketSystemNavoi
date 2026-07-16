using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Exceptions;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IUserTokenEpochStore _tokenEpochStore;

    public UserService(
        IUnitOfWork unitOfWork,
        IAppDbContext context,
        ICurrentMarketService currentMarketService,
        // MAJBURIY. Ilgari bu opsional (null default) edi — ya'ni DI'da ro'yxatdan
        // o'tkazish tushib qolsa, xavfsizlik nazorati jimgina o'chib qolardi:
        // TokensInvalidBeforeUtc DB'ga yozilaverardi, lekin kesh yangilanmagani
        // uchun bekor qilingan access tokenlar to'liq TTL davomida ishlayverardi.
        // Endi bunday konfiguratsiya startupda DI xatosi bilan darhol yiqiladi.
        IUserTokenEpochStore tokenEpochStore)
    {
        _unitOfWork = unitOfWork;
        _context = context;
        _currentMarketService = currentMarketService;
        _tokenEpochStore = tokenEpochStore;
    }

    /// <summary>
    /// Ishonchnoma o'zgarganda (parol, deaktivatsiya, o'chirish, ruxsatlar) foydalanuvchining
    /// BARCHA sessiyalarini o'ldiradi. Ikki qatlam kerak:
    ///   • refresh tokenlarni bekor qilish — aks holda o'g'irlangan refresh token parol
    ///     almashtirilgandan keyin ham cheksiz yangi access token chiqaraveradi;
    ///   • TokensInvalidBeforeUtc'ni stamplash — aks holda allaqachon berilgan access token
    ///     o'zining TTL'i tugagunicha (30 daqiqagacha) ishlayveradi, chunki har so'rovda
    ///     IsActive qayta tekshirilmaydi.
    /// SaveChangesAsync'DAN OLDIN chaqiriladi: ikkalasi ham user qatori bilan bitta
    /// tranzaksiyada commit bo'lsin. Commit'dan keyin <see cref="PublishEpoch"/>
    /// keshni yangilaydi.
    /// </summary>
    private async Task InvalidateSessionsAsync(User user, DateTime utcNow, CancellationToken cancellationToken)
    {
        await _unitOfWork.RefreshTokens.RevokeAllForUserAsync(user.Id, cancellationToken);
        user.TokensInvalidBeforeUtc = utcNow;
    }

    /// <summary>
    /// Commit MUVAFFAQIYATLI bo'lgandan keyin epoch keshini yangilaydi (hot-path
    /// lookup shu keshdan o'qiladi). Kesh-only: DB'ga yozuvni InvalidateSessionsAsync
    /// foydalanuvchi qatori bilan bitta tranzaksiyada allaqachon qilgan.
    /// Commit'gacha chaqirilsa, rollback bo'lgan o'zgarish keshda qolib ketardi.
    /// </summary>
    private void PublishEpoch(Guid userId, DateTime utcNow)
        => _tokenEpochStore.Publish(userId, utcNow);

    public async Task<UserDto?> GetUserByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        // TryGetCurrentMarketId returns null for SuperAdmin (cross-tenant, no MarketId
        // in JWT). For regular tenant users it returns the scoped market id. EF Core
        // translates `u.MarketId == null` to `WHERE MarketId IS NULL`, which correctly
        // matches the SuperAdmin row in the database.
        var marketId = _currentMarketService.TryGetCurrentMarketId();

        var users = await _unitOfWork.Users.FindAsync(
            u => u.Id == id && u.MarketId == marketId,
            cancellationToken,
            includeProperties: "Market");
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

        // Admin, Seller, and Owner can be created here (an Owner may add a
        // co-Owner). Creating an Owner is additionally gated to Owner/SuperAdmin
        // callers in UsersController.CreateUser — an Admin holding users.manage
        // must NOT be able to mint an Owner and self-escalate. SuperAdmin is
        // never created through this tenant endpoint; it is provisioned
        // out-of-band.
        if (role is not (Role.Admin or Role.Seller or Role.Owner))
            throw new InvalidOperationException("Faqat Owner, Admin yoki Seller foydalanuvchi yaratish mumkin.");

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
            throw new DuplicateUsernameException(request.Username);

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

        var wasActive = user.IsActive;
        var previousRole = user.Role;

        user.FullName = request.FullName;
        user.Role = newRole;
        user.IsActive = request.IsActive;

        // Update password only if provided
        var passwordChanged = false;
        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            passwordChanged = true;
        }

        // Sessiyalarni uzish shartlari:
        //  • parol almashtirildi,
        //  • user deaktivatsiya qilindi (active → inactive),
        //  • ROL o'zgardi — rol JWT ichiga muzlatib qo'yiladi (ClaimTypes.Role) va
        //    ruxsat tekshiruvlari o'shanga qaraydi. Busiz Admin'dan Seller'ga
        //    tushirilgan xodim access token muddati tugaguncha (30 daqiqa) Admin
        //    bo'lib qolaverardi.
        var roleChanged = previousRole != newRole;
        var utcNow = DateTime.UtcNow;
        var invalidate = passwordChanged || (wasActive && !user.IsActive) || roleChanged;
        if (invalidate)
            await InvalidateSessionsAsync(user, utcNow, cancellationToken);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        if (invalidate)
            PublishEpoch(user.Id, utcNow);

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
        var passwordChanged = false;
        if (!string.IsNullOrWhiteSpace(request.CurrentPassword) &&
            !string.IsNullOrWhiteSpace(request.NewPassword))
        {
            // Verify current password
            if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                throw new UnauthorizedAccessException("Current password is incorrect");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            passwordChanged = true;
        }

        // "Parolimni o'zgartirdim" — bu odatda aynan o'g'irlangan sessiyani uzish uchun
        // qilinadi. Barcha sessiyalar (shu jumladan chaqiruvchiniki ham) yopiladi;
        // klient qayta login qiladi.
        var utcNow = DateTime.UtcNow;
        if (passwordChanged)
            await InvalidateSessionsAsync(user, utcNow, cancellationToken);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        if (passwordChanged)
            PublishEpoch(user.Id, utcNow);

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

        // O'chirilgan user hozirning o'zida chiqarib yuborilishi kerak — soft-delete
        // qatorni yashiradi, lekin uning access token'i hech narsa tekshirmasdan
        // yana 30 daqiqa POS'da ishlayverardi.
        var utcNow = DateTime.UtcNow;
        await InvalidateSessionsAsync(user, utcNow, cancellationToken);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        PublishEpoch(user.Id, utcNow);
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

        // Deaktivatsiya = "bu odam endi ishlamaydi". IsActive har so'rovda qayta
        // tekshirilmaydi, shuning uchun sessiyalarni shu yerda uzamiz.
        var utcNow = DateTime.UtcNow;
        await InvalidateSessionsAsync(user, utcNow, cancellationToken);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        PublishEpoch(user.Id, utcNow);
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
    /// The permission set is baked into the JWT ("perm" claims), so the change only
    /// takes effect once the old token dies — we therefore kill the user's sessions
    /// here, which forces a re-login and makes a permission REVOKE take effect at once.
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
        var previous = user.Permissions?.ToHashSet() ?? new HashSet<string>();
        var ordered = PermissionKeys.All.Where(requested.Contains).ToList();
        user.Permissions = ordered;

        // If the requested set exactly matches the role default, treat this as
        // a "reset" — clear the customisation flag so the user inherits future
        // default changes automatically. Any other explicit set (including
        // intentionally empty) marks the user as customised.
        // SetEquals is order-independent — safe even if PermissionKeys.All order changes.
        var roleDefault = PermissionDefaults.ForRole(user.Role);
        user.IsPermissionsCustomized = !ordered.ToHashSet().SetEquals(roleDefault);

        // Sessiyani FAQAT ruxsat OLIB TASHLANGANDA uzamiz.
        //
        // Ilgari bu shartsiz ishlardi: Owner kassirning ruxsatlar oynasini ochib,
        // hech narsani o'zgartirmasdan "Saqlash" bossa ham — yoki aksincha, YANGI
        // ruxsat QO'SHSA ham — kassir savat o'rtasida tizimdan uchib ketardi.
        // Xavfsizlik nuqtai nazaridan faqat imtiyoz KAMAYISHI shoshilinch:
        // tokendagi eski (kengroq) ruxsatlar to'plami darhol yaroqsiz bo'lishi kerak.
        // Ruxsat qo'shilganda esa eski token shunchaki kamroq narsaga ega bo'ladi —
        // u tabiiy ravishda 30 daqiqada yangilanadi.
        var revoked = previous.Except(ordered).Any();

        var utcNow = DateTime.UtcNow;
        if (revoked)
            await InvalidateSessionsAsync(user, utcNow, cancellationToken);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        if (revoked)
            PublishEpoch(user.Id, utcNow);

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
            user.GetEffectivePermissions(),
            user.Market?.Name
        );
    }
}
