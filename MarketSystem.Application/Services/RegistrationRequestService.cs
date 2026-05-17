using System.Text.RegularExpressions;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class RegistrationRequestService : IRegistrationRequestService
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
        // The User entity's query filter already hides soft-deleted rows. Per the
        // SuperAdmin spec ("ishlayotgan userlar"), we additionally hide deactivated
        // owners; deactivated accounts can still be inspected via a future
        // /api/SuperAdmin/owners/all endpoint if needed.
        var owners = await _context.Users
            .AsNoTracking()
            .Include(u => u.Market)
            .Where(u => u.Role == Role.Owner && u.IsActive)
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync(cancellationToken);

        return owners.Select(u => new OwnerSummaryDto(
            u.Id,
            u.FullName,
            u.Username,
            u.Phone,
            u.IsActive,
            u.MarketId,
            u.Market?.Name,
            u.CreatedAt
        ));
    }

    public async Task<ApproveRegistrationResultDto> ApproveAsync(Guid requestId, ApproveRegistrationRequestDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Username) || dto.Username.Length < 3)
            throw new InvalidOperationException("Username kamida 3 ta belgidan iborat bo'lsin.");
        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 8)
            throw new InvalidOperationException("Parol kamida 8 ta belgidan iborat bo'lsin.");
        if (string.IsNullOrWhiteSpace(dto.MarketName))
            throw new InvalidOperationException("Do'kon nomini kiriting.");

        Language language = dto.Language?.ToLowerInvariant() switch
        {
            "uz" => Language.Uzbek,
            "ru" => Language.Russian,
            _ => Language.Uzbek
        };

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                // Re-read the request INSIDE the transaction with a row lock so a
                // concurrent SuperAdmin can't pass the same Pending check. xmin
                // adds a second layer of protection at SaveChanges time.
                var request = await _context.RegistrationRequests
                    .FromSqlInterpolated($"SELECT *, xmin FROM \"RegistrationRequests\" WHERE \"Id\" = {requestId} FOR UPDATE")
                    .FirstOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("So'rov topilmadi.");

                if (request.Status != RegistrationRequestStatus.Pending)
                    throw new InvalidOperationException($"So'rov allaqachon ko'rib chiqilgan ({request.Status}).");

                // Belt-and-braces unique checks before INSERTs — gives nicer error
                // messages than letting Postgres surface a 23505.
                if (await _context.Users.AnyAsync(u => u.Username == dto.Username, cancellationToken))
                    throw new InvalidOperationException($"'{dto.Username}' allaqachon ishlatilgan.");
                if (await _context.Markets.AnyAsync(m => m.Name == dto.MarketName, cancellationToken))
                    throw new InvalidOperationException($"'{dto.MarketName}' nomli do'kon allaqachon mavjud.");

                var subdomain = string.IsNullOrWhiteSpace(dto.Subdomain)
                    ? GenerateSubdomain(dto.Username)
                    : dto.Subdomain.Trim().ToLowerInvariant();

                if (!Regex.IsMatch(subdomain, @"^[a-z0-9][a-z0-9\-]{1,48}[a-z0-9]$"))
                    throw new InvalidOperationException(
                        "Subdomen faqat kichik harf, raqam va '-' belgisidan iborat bo'lishi, " +
                        "3–50 belgi uzunligida bo'lishi va harf/raqam bilan boshlanib-tugashi kerak.");

                if (await _context.Markets.AnyAsync(m => m.Subdomain == subdomain, cancellationToken))
                    throw new InvalidOperationException($"'{subdomain}' subdomeni allaqachon band.");

                var userId = Guid.NewGuid();
                var user = new User
                {
                    Id = userId,
                    FullName = request.FullName,
                    Username = dto.Username,
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
                    Name = dto.MarketName.Trim(),
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
                    payload: new { CreatedUserId = userId, CreatedMarketId = market.Id, Username = dto.Username, MarketName = market.Name },
                    cancellationToken);

                return new ApproveRegistrationResultDto(
                    request.Id,
                    user.Id,
                    user.Username,
                    market.Id,
                    market.Name
                );
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
                var request = await _context.RegistrationRequests
                    .FromSqlInterpolated($"SELECT *, xmin FROM \"RegistrationRequests\" WHERE \"Id\" = {requestId} FOR UPDATE")
                    .FirstOrDefaultAsync(cancellationToken);
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

    private static string GenerateSubdomain(string username)
    {
        var cleaned = new string(username.ToLowerInvariant().Where(char.IsLetterOrDigit).ToArray());
        if (string.IsNullOrEmpty(cleaned)) cleaned = "market";
        return $"{cleaned}{Guid.NewGuid().ToString("N")[..6]}";
    }

    // PostgreSQL always includes the SQLSTATE code "23505" in the message for unique violations.
    // Checking the message avoids a direct Npgsql package reference in the Application layer.
    private static bool IsUniqueViolation(DbUpdateException ex) =>
        ex.InnerException?.Message?.Contains("23505") == true;
}
