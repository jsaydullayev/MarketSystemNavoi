using System.Text.RegularExpressions;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

/// <summary>
/// M6 — RegistrationRequestService is <c>partial</c> so a future PR can lift
/// its three natural sub-modules into their own files without renaming the
/// type or touching call-sites:
///   • <c>RegistrationRequestService.Submit.cs</c> — public sign-up flow
///     (SubmitAsync, validation rules, dedup).
///   • <c>RegistrationRequestService.Review.cs</c> — SuperAdmin review
///     actions (ApproveAsync, RejectAsync, listing).
///   • <c>RegistrationRequestService.cs</c> (this file) — shared helpers
///     and the constructor.
/// The partial declaration is preparation only — no code moved yet — but
/// it unblocks an incremental split without a single big rename PR.
/// </summary>
public partial class RegistrationRequestService : IRegistrationRequestService
{
    private readonly IAppDbContext _context;
    private readonly ILogger<RegistrationRequestService> _logger;
    private readonly IAuditLogService _auditLog;

    public RegistrationRequestService(
        IAppDbContext context,
        ILogger<RegistrationRequestService> logger,
        IAuditLogService auditLog)
    {
        _context = context;
        _logger = logger;
        _auditLog = auditLog;
    }

    public async Task<Guid> SubmitAsync(SubmitRegistrationRequestDto dto, CancellationToken cancellationToken = default)
    {
        // DTO record has a default ctor that maps unset fields to string.Empty,
        // but System.Text.Json will preserve an explicit `null` in the payload —
        // null-coalesce so the validation message wins instead of an NRE.
        var fullName = dto.FullName ?? string.Empty;
        var rawPhone = dto.Phone ?? string.Empty;

        if (string.IsNullOrWhiteSpace(fullName) || fullName.Trim().Length < 2)
            throw new InvalidOperationException("Ism va familiyani kiriting.");

        var phone = NormalizePhone(rawPhone);

        var request = new RegistrationRequest
        {
            Id = Guid.NewGuid(),
            FullName = fullName.Trim(),
            Phone = phone,
            Status = RegistrationRequestStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _context.RegistrationRequests.Add(request);
        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (IsUniqueViolation(ex))
        {
            // Race: another submission with the same phone won the unique index.
            // We swallow the conflict deliberately — the public controller maps any
            // failure to a generic "Adminga yubordik" so a stranger can't probe
            // whether a phone is in the queue.
            _logger.LogInformation("Duplicate pending submission for {Phone} rejected by unique index.", phone);
            throw new InvalidOperationException("DUPLICATE_PENDING");
        }

        _logger.LogInformation("Registration request submitted: {RequestId} for {Phone}", request.Id, phone);
        return request.Id;
    }

    public async Task<IEnumerable<RegistrationRequestDto>> ListAsync(RegistrationRequestStatus? status, CancellationToken cancellationToken = default)
    {
        var query = _context.RegistrationRequests
            .AsNoTracking()
            .Include(r => r.ProcessedByUser)
            .AsQueryable();

        if (status.HasValue)
            query = query.Where(r => r.Status == status.Value);

        query = query.OrderByDescending(r => r.CreatedAt);

        var items = await query.ToListAsync(cancellationToken);

        return items.Select(r => new RegistrationRequestDto(
            r.Id,
            r.FullName,
            r.Phone,
            r.Status.ToString(),
            r.CreatedAt,
            r.ProcessedAt,
            r.ProcessedByUser?.FullName,
            r.CreatedUserId,
            r.CreatedMarketId,
            r.RejectReason
        ));
    }

    public async Task<IEnumerable<OwnerSummaryDto>> ListOwnersAsync(CancellationToken cancellationToken = default)
    {
        // Show every non-deleted Owner — including deactivated ones — so the
        // operator can re-activate them through UpdateOwner. Soft-deleted
        // accounts are still hidden via the global query filter on User.
        // Active owners come first so the common case (managing the live
        // tenant list) stays at the top of the list.
        var owners = await _context.Users
            .AsNoTracking()
            .Include(u => u.Market)
            .Where(u => u.Role == Role.Owner)
            .OrderByDescending(u => u.IsActive)
            .ThenByDescending(u => u.CreatedAt)
            .ToListAsync(cancellationToken);

        return owners.Select(u => new OwnerSummaryDto(
            u.Id,
            u.FullName,
            u.Username,
            u.Phone,
            u.IsActive,
            u.MarketId,
            u.Market?.Name,
            u.Market?.IsBlocked ?? false,
            u.CreatedAt
        ));
    }

    public async Task<ApproveRegistrationResultDto> ApproveAsync(Guid requestId, ApproveRegistrationRequestDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        var username = NormalizeUsername(dto.Username);
        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 8)
            throw new InvalidOperationException("Parol kamida 8 ta belgidan iborat bo'lsin.");
        if (string.IsNullOrWhiteSpace(dto.MarketName) || dto.MarketName.Trim().Length < 3)
            throw new InvalidOperationException("Do'kon nomini kiriting (kamida 3 belgi).");
        var marketName = dto.MarketName.Trim();

        Language language = dto.Language?.ToLowerInvariant() switch
        {
            "uz" => Language.Uzbek,
            "ru" => Language.Russian,
            _ => Language.Uzbek
        };

        var subdomain = string.IsNullOrWhiteSpace(dto.Subdomain)
            ? GenerateSubdomain(username)
            : ValidateAndNormalizeSubdomain(dto.Subdomain);

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                // Y6 — Re-read INSIDE the transaction with a row lock so a
                // concurrent SuperAdmin can't pass the same Pending check.
                // FOR UPDATE is PostgreSQL-only; the InMemory test provider
                // falls back to a plain query. xmin on the row still catches
                // concurrent SaveChanges in both providers, so correctness is
                // preserved.
                var request = await LoadRequestForUpdateAsync(requestId, cancellationToken)
                    ?? throw new KeyNotFoundException("So'rov topilmadi.");

                if (request.Status != RegistrationRequestStatus.Pending)
                    throw new InvalidOperationException($"So'rov allaqachon ko'rib chiqilgan ({request.Status}).");

                // Belt-and-braces unique checks. The case-insensitive lookups
                // catch operator typos ("Sardor" vs "sardor"); the DB unique
                // constraint is the final source of truth — see the catch
                // block below.
                if (await _context.Users.AnyAsync(u => u.Username == username, cancellationToken))
                    throw new InvalidOperationException($"'{username}' allaqachon ishlatilgan.");
                if (await MarketNameTakenAsync(marketName, excludeMarketId: null, cancellationToken))
                    throw new InvalidOperationException($"'{marketName}' nomli do'kon allaqachon mavjud.");
                if (await _context.Markets.AnyAsync(m => m.Subdomain == subdomain, cancellationToken))
                    throw new InvalidOperationException($"'{subdomain}' subdomeni allaqachon band.");

                var userId = Guid.NewGuid();
                var user = new User
                {
                    Id = userId,
                    FullName = request.FullName,
                    Username = username,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                    Phone = request.Phone,
                    Role = Role.Owner,
                    Language = language,
                    IsActive = true,
                    MarketId = null
                };
                await _context.Users.AddAsync(user, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);

                var market = new Market
                {
                    Name = marketName,
                    Subdomain = subdomain,
                    IsActive = true,
                    OwnerId = userId
                };
                await _context.Markets.AddAsync(market, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);

                _context.CashRegisters.Add(new CashRegister
                {
                    Id = Guid.NewGuid(),
                    MarketId = market.Id,
                    CurrentBalance = 0m,
                    LastUpdated = DateTime.UtcNow
                });

                user.MarketId = market.Id;

                request.Status = RegistrationRequestStatus.Approved;
                request.ProcessedAt = DateTime.UtcNow;
                request.ProcessedByUserId = superAdminUserId;
                request.CreatedUserId = userId;
                request.CreatedMarketId = market.Id;

                await _context.SaveChangesAsync(cancellationToken);
                await tx.CommitAsync(cancellationToken);

                _logger.LogInformation(
                    "Registration approved: RequestId={RequestId} UserId={UserId} MarketId={MarketId} BySuperAdmin={SuperAdminId}",
                    requestId, userId, market.Id, superAdminUserId);

                await _auditLog.LogActionAsync(
                    entityType: "RegistrationRequest",
                    entityId: requestId,
                    action: "Approved",
                    userId: superAdminUserId,
                    payload: new { CreatedUserId = userId, CreatedMarketId = market.Id, Username = username, MarketName = market.Name },
                    cancellationToken);

                return new ApproveRegistrationResultDto(
                    request.Id,
                    user.Id,
                    user.Username,
                    market.Id,
                    market.Name
                );
            }
            catch (DbUpdateException ex) when (IsUniqueViolation(ex))
            {
                // Race: a parallel approve/create slipped through between our
                // AnyAsync check and the INSERT. Convert to a clean 400 so the
                // operator sees an actionable message instead of a 500.
                await tx.RollbackAsync(cancellationToken);
                throw new InvalidOperationException(
                    "Username, do'kon nomi yoki subdomain allaqachon band. Iltimos, qayta tekshiring.");
            }
            catch (Exception)
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task<bool> RejectAsync(Guid requestId, string reason, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(reason))
            throw new InvalidOperationException("Rad etish sababini kiriting.");

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                // Y6 — FOR UPDATE on PostgreSQL, fall back to a plain read on
                // the InMemory test provider. See ApproveAsync for the full
                // rationale.
                var request = await LoadRequestForUpdateAsync(requestId, cancellationToken);
                if (request == null) return false;

                if (request.Status == RegistrationRequestStatus.Rejected) return true; // idempotent
                if (request.Status != RegistrationRequestStatus.Pending)
                    throw new InvalidOperationException($"So'rov allaqachon {request.Status} holatida.");

                request.Status = RegistrationRequestStatus.Rejected;
                request.ProcessedAt = DateTime.UtcNow;
                request.ProcessedByUserId = superAdminUserId;
                request.RejectReason = reason.Trim();

                await _context.SaveChangesAsync(cancellationToken);
                await tx.CommitAsync(cancellationToken);

                _logger.LogInformation(
                    "Registration rejected: RequestId={RequestId} BySuperAdmin={SuperAdminId}",
                    requestId, superAdminUserId);

                await _auditLog.LogActionAsync(
                    entityType: "RegistrationRequest",
                    entityId: requestId,
                    action: "Rejected",
                    userId: superAdminUserId,
                    payload: new { Reason = request.RejectReason },
                    cancellationToken);

                return true;
            }
            catch (Exception)
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task<CheckAvailabilityResultDto> CheckAvailabilityAsync(
        string? username,
        string? marketName,
        string? subdomain,
        CancellationToken cancellationToken = default)
    {
        // Each field is queried independently — null means "the caller didn't ask".
        // Inputs are normalised the same way Approve/Create do so the live check
        // matches what the server would actually save (e.g. "Sardor" → "sardor").
        bool? usernameAvailable = null;
        bool? marketNameAvailable = null;
        bool? subdomainAvailable = null;
        string? suggested = null;

        var u = username?.Trim().ToLowerInvariant();
        if (!string.IsNullOrEmpty(u) && u.Length >= 3)
        {
            usernameAvailable = !await _context.Users.AnyAsync(x => x.Username == u, cancellationToken);
        }

        var mRaw = marketName?.Trim();
        if (!string.IsNullOrEmpty(mRaw) && mRaw.Length >= 3)
        {
            // Case-insensitive — operator's "Sardor Market" collides with "sardor market".
            marketNameAvailable = !await MarketNameTakenAsync(mRaw, excludeMarketId: null, cancellationToken);
        }

        var s = subdomain?.Trim().ToLowerInvariant();
        if (!string.IsNullOrEmpty(s))
        {
            // Pre-validate format too so the UI flags "my market!" as taken-ish
            // (we don't expose the validation error here — UI handles its own
            // regex feedback — but a bad subdomain can never be available).
            if (!_subdomainPattern.IsMatch(s) || s.Length < 3 || s.Length > 63)
                subdomainAvailable = false;
            else
                subdomainAvailable = !await _context.Markets.AnyAsync(x => x.Subdomain == s, cancellationToken);
        }
        else if (!string.IsNullOrEmpty(u))
        {
            // Supplied a username but no subdomain — offer the auto-generated one
            // so the UI can show a live preview without the user having to type.
            suggested = GenerateSubdomain(u);
        }

        return new CheckAvailabilityResultDto(
            usernameAvailable,
            marketNameAvailable,
            subdomainAvailable,
            suggested);
    }

    public async Task<OwnerDetailDto?> GetOwnerDetailAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        // ListOwners hides soft-deleted rows via the query filter — we honour
        // that here for consistency. If we ever need to surface deleted owners
        // (e.g. an "archive" view), use IgnoreQueryFilters on a separate method.
        var owner = await _context.Users
            .AsNoTracking()
            .Include(u => u.Market)
            .FirstOrDefaultAsync(u => u.Id == userId && u.Role == Role.Owner, cancellationToken);
        if (owner == null) return null;

        var marketId = owner.MarketId;
        var stats = marketId.HasValue
            ? await ComputeOwnerStatsAsync(marketId.Value, cancellationToken)
            : new OwnerDetailStatsDto(0, 0, 0, 0, 0m);

        var marketDto = owner.Market is null
            ? null
            : new OwnerDetailMarketDto(
                owner.Market.Id,
                owner.Market.Name,
                owner.Market.Subdomain,
                owner.Market.Description,
                owner.Market.IsActive,
                owner.Market.IsBlocked,
                owner.Market.BlockedAt,
                owner.Market.BlockedReason,
                owner.Market.ExpiresAt,
                owner.Market.CreatedAt);

        return new OwnerDetailDto(
            owner.Id,
            owner.FullName,
            owner.Username,
            owner.Phone,
            owner.IsActive,
            owner.Language.ToString().ToLowerInvariant(),
            owner.CreatedAt,
            marketDto,
            stats);
    }

    private async Task<OwnerDetailStatsDto> ComputeOwnerStatsAsync(int marketId, CancellationToken cancellationToken)
    {
        // Each count is a separate round-trip — fine because this is rare (one
        // page load per market detail view). If this ever becomes hot, fold
        // them into a single raw-SQL query.
        var productsCount = await _context.Products.CountAsync(p => p.MarketId == marketId, cancellationToken);
        var salesCount = await _context.Sales.CountAsync(s => s.MarketId == marketId, cancellationToken);
        var customersCount = await _context.Customers.CountAsync(c => c.MarketId == marketId, cancellationToken);
        // "Cashiers" in the UI means "every non-owner staff member who can ring
        // up a sale" — both Sellers and Admins log into the POS. Counting only
        // Sellers undercounted markets that delegate to an Admin.
        var staffCount = await _context.Users.CountAsync(
            u => u.MarketId == marketId
                 && u.Role != Role.Owner
                 && u.Role != Role.SuperAdmin
                 && u.IsActive,
            cancellationToken);
        var outstandingDebt = await _context.Debts
            .Where(d => d.MarketId == marketId)
            .SumAsync(d => (decimal?)d.RemainingDebt, cancellationToken) ?? 0m;

        return new OwnerDetailStatsDto(productsCount, salesCount, customersCount, staffCount, outstandingDebt);
    }

    public async Task<ApproveRegistrationResultDto> CreateOwnerAsync(CreateOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName) || dto.FullName.Trim().Length < 2)
            throw new InvalidOperationException("Ism va familiyani kiriting.");
        var username = NormalizeUsername(dto.Username);
        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 8)
            throw new InvalidOperationException("Parol kamida 8 ta belgidan iborat bo'lsin.");
        if (string.IsNullOrWhiteSpace(dto.MarketName) || dto.MarketName.Trim().Length < 3)
            throw new InvalidOperationException("Do'kon nomini kiriting (kamida 3 belgi).");

        var marketName = dto.MarketName.Trim();
        var phone = NormalizePhone(dto.Phone);

        Language language = dto.Language?.ToLowerInvariant() switch
        {
            "ru" => Language.Russian,
            _ => Language.Uzbek
        };

        var subdomain = string.IsNullOrWhiteSpace(dto.Subdomain)
            ? GenerateSubdomain(username)
            : ValidateAndNormalizeSubdomain(dto.Subdomain);

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                if (await _context.Users.AnyAsync(u => u.Username == username, cancellationToken))
                    throw new InvalidOperationException($"'{username}' allaqachon ishlatilgan.");
                if (await MarketNameTakenAsync(marketName, excludeMarketId: null, cancellationToken))
                    throw new InvalidOperationException($"'{marketName}' nomli do'kon allaqachon mavjud.");
                if (await _context.Markets.AnyAsync(m => m.Subdomain == subdomain, cancellationToken))
                    throw new InvalidOperationException($"'{subdomain}' subdomeni allaqachon band.");

                var userId = Guid.NewGuid();
                var user = new User
                {
                    Id = userId,
                    FullName = dto.FullName.Trim(),
                    Username = username,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                    Phone = phone,
                    Role = Role.Owner,
                    Language = language,
                    IsActive = true,
                    MarketId = null
                };
                await _context.Users.AddAsync(user, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);

                var market = new Market
                {
                    Name = marketName,
                    Subdomain = subdomain,
                    IsActive = true,
                    OwnerId = userId
                };
                await _context.Markets.AddAsync(market, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);

                _context.CashRegisters.Add(new CashRegister
                {
                    Id = Guid.NewGuid(),
                    MarketId = market.Id,
                    CurrentBalance = 0m,
                    LastUpdated = DateTime.UtcNow
                });

                user.MarketId = market.Id;

                await _context.SaveChangesAsync(cancellationToken);
                await tx.CommitAsync(cancellationToken);

                _logger.LogInformation(
                    "Owner manually created: UserId={UserId} MarketId={MarketId} BySuperAdmin={SuperAdminId}",
                    userId, market.Id, superAdminUserId);

                await _auditLog.LogActionAsync(
                    entityType: "Owner",
                    entityId: userId,
                    action: "CreatedManually",
                    userId: superAdminUserId,
                    payload: new { CreatedUserId = userId, CreatedMarketId = market.Id, Username = username, MarketName = market.Name },
                    cancellationToken);

                return new ApproveRegistrationResultDto(
                    Guid.Empty, // No backing request id for a manual create.
                    user.Id,
                    user.Username,
                    market.Id,
                    market.Name);
            }
            catch (DbUpdateException ex) when (IsUniqueViolation(ex))
            {
                await tx.RollbackAsync(cancellationToken);
                throw new InvalidOperationException(
                    "Username, do'kon nomi yoki subdomain allaqachon band. Iltimos, qayta tekshiring.");
            }
            catch (Exception)
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task<OwnerDetailDto> UpdateOwnerAsync(Guid userId, UpdateOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName) || dto.FullName.Trim().Length < 2)
            throw new InvalidOperationException("Ism va familiyani kiriting.");
        if (string.IsNullOrWhiteSpace(dto.MarketName) || dto.MarketName.Trim().Length < 3)
            throw new InvalidOperationException("Do'kon nomini kiriting (kamida 3 belgi).");

        var newMarketName = dto.MarketName.Trim();
        var newSubdomain = string.IsNullOrWhiteSpace(dto.Subdomain)
            ? null
            : ValidateAndNormalizeSubdomain(dto.Subdomain);

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var owner = await _context.Users
                    .Include(u => u.Market)
                    .FirstOrDefaultAsync(u => u.Id == userId && u.Role == Role.Owner, cancellationToken)
                    ?? throw new KeyNotFoundException("Owner topilmadi.");

                // ── Owner fields ────────────────────────────────────────────
                owner.FullName = dto.FullName.Trim();
                if (!string.IsNullOrWhiteSpace(dto.Phone))
                    owner.Phone = NormalizePhone(dto.Phone);
                if (!string.IsNullOrWhiteSpace(dto.Language))
                {
                    owner.Language = dto.Language.ToLowerInvariant() switch
                    {
                        "ru" => Language.Russian,
                        _ => Language.Uzbek
                    };
                }
                if (dto.OwnerActive.HasValue)
                    owner.IsActive = dto.OwnerActive.Value;

                // ── Market fields (only if the Owner has a Market) ──────────
                if (owner.Market is null)
                    throw new InvalidOperationException("Owner uchun do'kon biriktirilmagan.");

                var market = owner.Market;

                // Case-insensitive comparison — matches the create-time check
                // so the operator can fix capitalisation without tripping the
                // uniqueness guard against their own market.
                if (!string.Equals(market.Name, newMarketName, StringComparison.OrdinalIgnoreCase))
                {
                    if (await MarketNameTakenAsync(newMarketName, market.Id, cancellationToken))
                        throw new InvalidOperationException($"'{newMarketName}' nomli do'kon allaqachon mavjud.");
                }
                market.Name = newMarketName;

                if (newSubdomain != null
                    && !string.Equals(market.Subdomain, newSubdomain, StringComparison.Ordinal))
                {
                    if (await _context.Markets.AnyAsync(m => m.Id != market.Id && m.Subdomain == newSubdomain, cancellationToken))
                        throw new InvalidOperationException($"'{newSubdomain}' subdomeni allaqachon band.");
                    market.Subdomain = newSubdomain;
                }

                if (dto.Description != null) market.Description = dto.Description.Trim();
                if (dto.MarketActive.HasValue) market.IsActive = dto.MarketActive.Value;
                if (dto.ExpiresAt.HasValue) market.ExpiresAt = dto.ExpiresAt.Value;

                await _context.SaveChangesAsync(cancellationToken);
                await tx.CommitAsync(cancellationToken);

                _logger.LogInformation(
                    "Owner updated: UserId={UserId} MarketId={MarketId} BySuperAdmin={SuperAdminId}",
                    userId, market.Id, superAdminUserId);

                await _auditLog.LogActionAsync(
                    entityType: "Owner",
                    entityId: userId,
                    action: "Updated",
                    userId: superAdminUserId,
                    payload: new { MarketId = market.Id, MarketName = market.Name, OwnerActive = owner.IsActive, MarketActive = market.IsActive },
                    cancellationToken);

                // Reload through the detail path so the response includes stats.
                var refreshed = await GetOwnerDetailAsync(userId, cancellationToken);
                return refreshed!;
            }
            catch (DbUpdateException ex) when (IsUniqueViolation(ex))
            {
                await tx.RollbackAsync(cancellationToken);
                throw new InvalidOperationException(
                    "Do'kon nomi yoki subdomain allaqachon band. Iltimos, qayta tekshiring.");
            }
            catch (Exception)
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task<bool> DeleteOwnerAsync(Guid userId, DeleteOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Reason))
            throw new InvalidOperationException("O'chirish sababini kiriting.");
        if (string.IsNullOrWhiteSpace(dto.ConfirmMarketName))
            throw new InvalidOperationException("Do'kon nomini tasdiqlash uchun kiriting.");

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var owner = await _context.Users
                    .Include(u => u.Market)
                    .FirstOrDefaultAsync(u => u.Id == userId && u.Role == Role.Owner, cancellationToken);
                if (owner == null) return false;

                // Typed-confirmation guard — mirrors the destructive-action dialog
                // so a fat-fingered DELETE can't take out the wrong tenant.
                if (owner.Market == null ||
                    !string.Equals(owner.Market.Name.Trim(), dto.ConfirmMarketName.Trim(), StringComparison.Ordinal))
                {
                    throw new InvalidOperationException("Tasdiqlash do'kon nomi mos kelmadi.");
                }

                // Soft-delete: User goes to IsDeleted (hidden by the global query
                // filter), Market is deactivated (still readable in the DB for
                // forensics but no Tenant resolves to it). Historical sales,
                // products, debts, etc. are intentionally left intact.
                owner.IsActive = false;
                owner.IsDeleted = true;
                owner.Market.IsActive = false;

                // Cascade-deactivate every non-Owner user in this market so they
                // can't log in either. Previously this only touched Sellers —
                // any Admin under the market would have remained reachable.
                var staff = await _context.Users
                    .Where(u => u.MarketId == owner.Market.Id
                                && u.Role != Role.Owner
                                && u.Role != Role.SuperAdmin
                                && u.IsActive)
                    .ToListAsync(cancellationToken);
                foreach (var member in staff)
                    member.IsActive = false;

                await _context.SaveChangesAsync(cancellationToken);
                await tx.CommitAsync(cancellationToken);

                _logger.LogWarning(
                    "Owner soft-deleted: UserId={UserId} MarketId={MarketId} BySuperAdmin={SuperAdminId} Reason={Reason}",
                    userId, owner.Market.Id, superAdminUserId, dto.Reason);

                await _auditLog.LogActionAsync(
                    entityType: "Owner",
                    entityId: userId,
                    action: "SoftDeleted",
                    userId: superAdminUserId,
                    payload: new
                    {
                        MarketId = owner.Market.Id,
                        MarketName = owner.Market.Name,
                        Reason = dto.Reason.Trim(),
                        StaffDeactivated = staff.Count
                    },
                    cancellationToken);

                return true;
            }
            catch (Exception)
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task<MarketBlockStatusDto> BlockMarketAsync(int marketId, BlockMarketDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Trim().Length < 3)
            throw new InvalidOperationException("Bloklash sababini kiriting (kamida 3 belgi).");

        var market = await _context.Markets.FirstOrDefaultAsync(m => m.Id == marketId, cancellationToken)
            ?? throw new KeyNotFoundException("Do'kon topilmadi.");

        // Idempotent — re-blocking refreshes the reason/timestamp/actor but
        // doesn't error. Operators rely on this when escalating from "warning"
        // to "blocked" reasons after a follow-up.
        market.IsBlocked = true;
        market.BlockedAt = DateTime.UtcNow;
        market.BlockedReason = dto.Reason.Trim();
        market.BlockedByUserId = superAdminUserId;

        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogWarning(
            "Market blocked: MarketId={MarketId} MarketName={MarketName} BySuperAdmin={SuperAdminId} Reason={Reason}",
            market.Id, market.Name, superAdminUserId, market.BlockedReason);

        await _auditLog.LogActionAsync(
            entityType: AuditEntityTypes.Market,
            entityId: Guid.Empty,                       // Market.Id is an int, not a Guid.
            action: AuditActions.Block,
            userId: superAdminUserId,
            payload: new { MarketId = market.Id, MarketName = market.Name, market.BlockedReason },
            cancellationToken);

        return new MarketBlockStatusDto(market.Id, market.Name, true, market.BlockedAt, market.BlockedReason);
    }

    public async Task<MarketBlockStatusDto> UnblockMarketAsync(int marketId, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        var market = await _context.Markets.FirstOrDefaultAsync(m => m.Id == marketId, cancellationToken)
            ?? throw new KeyNotFoundException("Do'kon topilmadi.");

        var wasBlocked = market.IsBlocked;
        market.IsBlocked = false;
        market.BlockedAt = null;
        market.BlockedReason = null;
        market.BlockedByUserId = null;

        await _context.SaveChangesAsync(cancellationToken);

        if (wasBlocked)
        {
            _logger.LogInformation(
                "Market unblocked: MarketId={MarketId} MarketName={MarketName} BySuperAdmin={SuperAdminId}",
                market.Id, market.Name, superAdminUserId);

            await _auditLog.LogActionAsync(
                entityType: AuditEntityTypes.Market,
                entityId: Guid.Empty,
                action: AuditActions.Unblock,
                userId: superAdminUserId,
                payload: new { MarketId = market.Id, MarketName = market.Name },
                cancellationToken);
        }

        return new MarketBlockStatusDto(market.Id, market.Name, false, null, null);
    }

    /// <summary>
    /// Normalise to strict E.164-like Uzbekistan format `+998XXXXXXXXX` (12 digits
    /// after the plus). Anything else throws — accepting "998..." and "+998..."
    /// as different values would break our partial unique index on Phone.
    /// </summary>
    private static string NormalizePhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
            throw new InvalidOperationException("Telefon raqamini kiriting.");

        var digits = new string(phone.Where(char.IsDigit).ToArray());
        // Accept: 9 digits (no country code), 12 digits starting 998, 13 with 00998.
        if (digits.Length == 9) digits = "998" + digits;
        else if (digits.Length == 14 && digits.StartsWith("00998")) digits = digits[2..];
        else if (digits.Length != 12 || !digits.StartsWith("998"))
            throw new InvalidOperationException("Telefon raqami formati noto'g'ri. Misol: +998 90 123 45 67.");

        return "+" + digits;
    }

    /// <summary>
    /// Usernames are stored lowercase + trimmed so that "Sardor", " sardor",
    /// and "sardor" can't coexist as separate accounts (PostgreSQL `=` is
    /// case-sensitive — without this the login query would non-deterministically
    /// pick a row when duplicates exist).
    /// </summary>
    private static string NormalizeUsername(string? username)
    {
        var u = (username ?? string.Empty).Trim().ToLowerInvariant();
        if (u.Length < 3)
            throw new InvalidOperationException("Username kamida 3 ta belgidan iborat bo'lsin.");
        return u;
    }

    // DNS-safe subdomain: lowercase letters/digits/hyphens, must start and end
    // with alphanumeric, 3–63 characters. Empty hyphens, dots, and underscores
    // would break the host header / cert lookup, so we reject them at the edge.
    private static readonly Regex _subdomainPattern = new(
        @"^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$",
        RegexOptions.Compiled);

    private static string ValidateAndNormalizeSubdomain(string raw)
    {
        var s = raw.Trim().ToLowerInvariant();
        if (s.Length < 3 || s.Length > 63 || !_subdomainPattern.IsMatch(s))
            throw new InvalidOperationException(
                "Subdomain noto'g'ri formatda. Faqat lotin harflari, raqamlar va '-' (3-63 belgi).");
        return s;
    }

    private static string GenerateSubdomain(string username)
    {
        var cleaned = new string(username.ToLowerInvariant().Where(char.IsLetterOrDigit).ToArray());
        if (string.IsNullOrEmpty(cleaned)) cleaned = "market";
        return $"{cleaned}{Guid.NewGuid().ToString("N")[..6]}";
    }

    /// <summary>
    /// Case-insensitive existence check for market names. Without this, two
    /// markets named "Sardor Market" and "sardor market" can coexist —
    /// confusing for operators and ambiguous for tenant lookup. EF Core
    /// translates `string.ToLower()` to PostgreSQL `LOWER(...)`, which is
    /// indexable; the unique constraint at the DB level is still
    /// <summary>
    /// Y6 — Re-read a RegistrationRequest inside the surrounding transaction.
    /// On PostgreSQL the query uses <c>SELECT … FOR UPDATE</c> so a parallel
    /// SuperAdmin review on the same row blocks until we commit. On the
    /// EF Core InMemory provider (test suite) raw SQL isn't supported, so
    /// we fall back to a plain query — xmin on the row catches the
    /// concurrent SaveChanges either way, but in tests we get the simpler
    /// "second write fails and retries" semantic instead of a real row lock.
    /// </summary>
    private async Task<RegistrationRequest?> LoadRequestForUpdateAsync(Guid requestId, CancellationToken ct)
    {
        var isPostgres = _context.Database.ProviderName?.Contains("InMemory") == false;
        if (isPostgres)
        {
            return await _context.RegistrationRequests
                .FromSqlInterpolated($"SELECT *, xmin FROM \"RegistrationRequests\" WHERE \"Id\" = {requestId} FOR UPDATE")
                .FirstOrDefaultAsync(ct);
        }
        return await _context.RegistrationRequests.FirstOrDefaultAsync(r => r.Id == requestId, ct);
    }

    /// <summary>
    /// case-sensitive but the application-layer check catches the
    /// case-only collision before INSERT.
    /// </summary>
    private async Task<bool> MarketNameTakenAsync(string name, int? excludeMarketId, CancellationToken ct)
    {
        var lowered = name.Trim().ToLowerInvariant();
        if (excludeMarketId.HasValue)
            return await _context.Markets.AnyAsync(
                m => m.Id != excludeMarketId.Value && m.Name.ToLower() == lowered, ct);
        return await _context.Markets.AnyAsync(m => m.Name.ToLower() == lowered, ct);
    }

    // PostgreSQL always includes the SQLSTATE code "23505" in the message for unique violations.
    // Checking the message avoids a direct Npgsql package reference in the Application layer.
    private static bool IsUniqueViolation(DbUpdateException ex) =>
        ex.InnerException?.Message?.Contains("23505") == true;
}
