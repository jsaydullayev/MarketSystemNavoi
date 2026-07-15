using System.Text.Json;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Application.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class AuditLogService : IAuditLogService, IAuditLogQueryService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AuditLogService> _logger;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IAppDbContext _context;

    public AuditLogService(
        IUnitOfWork unitOfWork,
        ILogger<AuditLogService> logger,
        ICurrentMarketService currentMarketService,
        IHttpContextAccessor httpContextAccessor,
        IAppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _currentMarketService = currentMarketService;
        _httpContextAccessor = httpContextAccessor;
        _context = context;
    }

    public async Task LogActionAsync(
        string entityType,
        Guid entityId,
        string action,
        Guid userId,
        object? payload = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var auditLog = BuildAuditLog(entityType, entityId, action, userId, payload);
            await _unitOfWork.AuditLogs.AddAsync(auditLog, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Audit log created: {EntityType} {EntityId} - {Action} by User {UserId}",
                entityType, entityId, action, userId);
        }
        catch (Exception ex)
        {
            // Audit logging is a non-critical side effect. Swallowing here is intentional
            // so that a DB write failure (e.g. transient timeout) never breaks the main
            // business operation. The error is still surfaced via the log.
            _logger.LogError(ex, "Failed to create audit log for {EntityType} {EntityId}",
                entityType, entityId);
        }
    }

    /// <summary>
    /// P6 — stage an audit-log row on the SHARED DbContext WITHOUT issuing a
    /// SaveChanges. The caller's next SaveChangesAsync batches the audit
    /// INSERT alongside the business write, saving one round trip per hot
    /// operation. Use this when:
    /// <list type="bullet">
    /// <item>The audit MUST be part of the same business transaction (audit
    /// row commits / rolls back together with the business state).</item>
    /// <item>The caller is going to call SaveChangesAsync within the next
    /// few statements.</item>
    /// </list>
    /// For the post-transaction audit pattern (fire-and-forget), keep using
    /// <see cref="LogActionAsync"/> so the audit error swallowing applies.
    /// </summary>
    public Task EnqueueActionAsync(
        string entityType,
        Guid entityId,
        string action,
        Guid userId,
        object? payload = null,
        CancellationToken cancellationToken = default)
    {
        var auditLog = BuildAuditLog(entityType, entityId, action, userId, payload);
        return _unitOfWork.AuditLogs.AddAsync(auditLog, cancellationToken);
    }

    private AuditLog BuildAuditLog(string entityType, Guid entityId, string action, Guid userId, object? payload) =>
        new()
        {
            Id = Guid.NewGuid(),
            EntityType = entityType,
            EntityId = entityId,
            Action = action,
            // Guid.Empty from callers (e.g. LoginFailed where the username
            // doesn't resolve to a real account) is normalised to NULL so
            // the row doesn't violate the FK to Users.
            UserId = userId == Guid.Empty ? null : userId,
            MarketId = _currentMarketService.TryGetCurrentMarketId(),
            Payload = payload != null ? JsonSerializer.Serialize(payload) : string.Empty,
            IpAddress = _httpContextAccessor.HttpContext?
                .Connection.RemoteIpAddress?.ToString(),
            CreatedAt = DateTime.UtcNow
        };

    public async Task LogSaleActionAsync(Guid saleId, string action, Guid userId, CancellationToken cancellationToken = default)
    {
        var sale = await _unitOfWork.Sales.GetByIdAsync(saleId, cancellationToken);
        if (sale != null)
        {
            await LogActionAsync("Sale", saleId, action, userId, new
            {
                SaleId = saleId,
                SellerId = sale.SellerId,
                CustomerId = sale.CustomerId,
                Status = sale.Status.ToString(),
                TotalAmount = sale.TotalAmount,
                PaidAmount = sale.PaidAmount
            }, cancellationToken);
        }
    }

    public async Task LogPaymentActionAsync(Guid paymentId, Guid userId, CancellationToken cancellationToken = default)
    {
        var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId, cancellationToken);
        if (payment != null)
        {
            await LogActionAsync("Payment", paymentId, "Create", userId, new
            {
                PaymentId = paymentId,
                SaleId = payment.SaleId,
                PaymentType = payment.PaymentType.ToString(),
                Amount = payment.Amount
            }, cancellationToken);
        }
    }

    public async Task LogZakupActionAsync(Guid zakupId, Guid userId, CancellationToken cancellationToken = default)
    {
        var zakup = await _unitOfWork.Zakups.GetByIdAsync(zakupId, cancellationToken);
        if (zakup != null)
        {
            await LogActionAsync("Zakup", zakupId, "Create", userId, new
            {
                ZakupId = zakupId,
                ProductId = zakup.ProductId,
                Quantity = zakup.Quantity,
                CostPrice = zakup.CostPrice
            }, cancellationToken);
        }
    }

    public async Task LogDebtActionAsync(Guid debtId, string action, Guid userId, CancellationToken cancellationToken = default)
    {
        var debt = await _unitOfWork.Debts.GetByIdAsync(debtId, cancellationToken);
        if (debt != null)
        {
            await LogActionAsync("Debt", debtId, action, userId, new
            {
                DebtId = debtId,
                SaleId = debt.SaleId,
                CustomerId = debt.CustomerId,
                TotalDebt = debt.TotalDebt,
                RemainingDebt = debt.RemainingDebt,
                Status = debt.Status.ToString()
            }, cancellationToken);
        }
    }

    // ─── Read API (Plan 07 Bosqich 2) ────────────────────────────────────

    // Bounds on `size` — small enough to keep payloads modest, large enough to
    // amortise round trips on a busy market's log. Page < 1 collapses to 1.
    private const int MinPageSize = 1;
    private const int MaxPageSize = 200;

    /// <inheritdoc />
    public async Task<PagedResult<AuditLogDto>> QueryAsync(
        AuditLogFilter filter,
        bool allowCrossMarket = false,
        CancellationToken cancellationToken = default)
    {
        // Fail-closed tenant guard: a non-SuperAdmin caller must be scoped to a
        // concrete market. If the controller's pin ever resolves to null (e.g.
        // a missing market claim), refuse rather than leak every tenant's logs.
        if (!allowCrossMarket && !filter.MarketId.HasValue)
            throw new InvalidOperationException("Audit log query requires a market scope.");

        var query = _context.AuditLogs.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.EntityType))
            query = query.Where(a => a.EntityType == filter.EntityType);
        if (!string.IsNullOrWhiteSpace(filter.Action))
            query = query.Where(a => a.Action == filter.Action);
        if (filter.UserId.HasValue)
            query = query.Where(a => a.UserId == filter.UserId.Value);
        if (filter.MarketId.HasValue)
            query = query.Where(a => a.MarketId == filter.MarketId.Value);
        if (filter.FromUtc.HasValue)
            query = query.Where(a => a.CreatedAt >= filter.FromUtc.Value);
        if (filter.ToUtc.HasValue)
            query = query.Where(a => a.CreatedAt < filter.ToUtc.Value);

        var total = await query.CountAsync(cancellationToken);

        var page = Math.Max(1, filter.Page);
        var size = Math.Clamp(filter.Size, MinPageSize, MaxPageSize);

        // The projection drives EF to emit a single LEFT JOIN to Users for
        // FullName — no Include needed, and anonymous rows (UserId NULL) come
        // back with UserName == null exactly as the DTO contract says.
        var items = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * size)
            .Take(size)
            .Select(a => new AuditLogDto(
                a.Id,
                a.EntityType,
                a.EntityId,
                a.Action,
                a.UserId,
                a.User != null ? a.User.FullName : null,
                a.Payload,
                a.IpAddress,
                a.MarketId,
                a.CreatedAt))
            .ToListAsync(cancellationToken);

        return PagedResult<AuditLogDto>.From(items, page, size, total);
    }

    // ─── Suspicious-activity detection (Plan 07 Bosqich 3) ───────────────

    // Thresholds and windows are deliberately hard-coded — they're the
    // detection rules, not configuration. Tune in code with a comment & test.
    private const int FailedLoginThreshold = 5;
    private const int FailedLoginWindowMinutes = 15;
    private const int BulkDeleteThreshold = 5;
    private const int BulkDeleteWindowMinutes = 10;

    /// <inheritdoc />
    public async Task<SuspiciousActivityReport> GetSuspiciousAsync(
        int? marketId,
        bool allowCrossMarket = false,
        CancellationToken cancellationToken = default)
    {
        // Fail-closed tenant guard — see QueryAsync.
        if (!allowCrossMarket && !marketId.HasValue)
            throw new InvalidOperationException("Suspicious-activity query requires a market scope.");

        var now = DateTime.UtcNow;
        var failedLoginBursts = await GetFailedLoginBurstsAsync(marketId, now, cancellationToken);
        var bulkDeleteBursts = await GetBulkDeleteBurstsAsync(marketId, now, cancellationToken);
        var recentErrors = await GetRecentErrorsAsync(marketId, now, cancellationToken);
        return new SuspiciousActivityReport(failedLoginBursts, bulkDeleteBursts, recentErrors);
    }

    // Recent server-side faults (5xx) recorded by the global exception handler.
    // Not a burst/threshold rule — just the latest problems the Owner/developer
    // should see, newest first, over the last day.
    private const int RecentErrorsWindowHours = 24;
    private const int RecentErrorsMax = 50;

    private async Task<IReadOnlyList<ErrorEntryDto>> GetRecentErrorsAsync(
        int? marketId, DateTime now, CancellationToken ct)
    {
        var since = now.AddHours(-RecentErrorsWindowHours);
        var query = _context.AuditLogs.AsNoTracking()
            .Where(a => a.EntityType == AuditEntityTypes.Error && a.CreatedAt >= since);
        if (marketId.HasValue)
            query = query.Where(a => a.MarketId == marketId.Value);

        var rows = await query
            .OrderByDescending(a => a.CreatedAt)
            .Take(RecentErrorsMax)
            .Select(a => new
            {
                a.Payload,
                a.CreatedAt,
                UserName = a.User != null ? a.User.FullName : null
            })
            .ToListAsync(ct);

        return rows.Select(r => ParseError(r.Payload, r.CreatedAt, r.UserName)).ToList();
    }

    /// <summary>Pull the status code / message / path out of an Error payload.
    /// Defensive against malformed JSON — a bad row degrades to a generic 500
    /// entry rather than crashing the report.</summary>
    private static ErrorEntryDto ParseError(string payload, DateTime createdAt, string? userName)
    {
        int status = 500;
        string message = string.Empty;
        string? path = null;
        string? method = null;
        try
        {
            using var doc = JsonDocument.Parse(payload);
            var root = doc.RootElement;
            if (root.ValueKind == JsonValueKind.Object)
            {
                if (root.TryGetProperty("StatusCode", out var s) && s.TryGetInt32(out var sc)) status = sc;
                if (root.TryGetProperty("Message", out var m) && m.ValueKind == JsonValueKind.String) message = m.GetString() ?? string.Empty;
                if (root.TryGetProperty("Path", out var p) && p.ValueKind == JsonValueKind.String) path = p.GetString();
                if (root.TryGetProperty("Method", out var me) && me.ValueKind == JsonValueKind.String) method = me.GetString();
            }
        }
        catch (JsonException)
        {
            // swallowed — a bad payload doesn't crash the report.
        }
        return new ErrorEntryDto(status, message, path, method, userName, createdAt);
    }

    private async Task<IReadOnlyList<FailedLoginBurstDto>> GetFailedLoginBurstsAsync(
        int? marketId, DateTime now, CancellationToken ct)
    {
        var since = now.AddMinutes(-FailedLoginWindowMinutes);
        var query = _context.AuditLogs.AsNoTracking()
            .Where(a => a.Action == AuditActions.LoginFailed
                     && a.EntityType == AuditEntityTypes.Auth
                     && a.CreatedAt >= since);
        if (marketId.HasValue)
            query = query.Where(a => a.MarketId == marketId.Value);

        // Pull the slim candidate set, group client-side. The window + index on
        // (EntityType, EntityId, CreatedAt) keeps this cheap, and grouping by
        // a JSON-payload field is easier to do in memory than in SQL —
        // critically, it keeps the test suite (InMemory provider, no jsonb)
        // exercising the same code path as production.
        var rows = await query
            .Select(a => new { a.Payload, a.CreatedAt, a.IpAddress })
            .ToListAsync(ct);

        return rows
            .Select(r => new { Username = TryExtractUsername(r.Payload), r.CreatedAt, r.IpAddress })
            .Where(r => !string.IsNullOrEmpty(r.Username))
            .GroupBy(r => r.Username!)
            .Where(g => g.Count() >= FailedLoginThreshold)
            .Select(g => new FailedLoginBurstDto(
                g.Key,
                g.Count(),
                g.Min(x => x.CreatedAt),
                g.Max(x => x.CreatedAt),
                g.Where(x => !string.IsNullOrEmpty(x.IpAddress))
                 .Select(x => x.IpAddress!)
                 .Distinct()
                 .OrderBy(x => x)
                 .ToList()))
            .OrderByDescending(b => b.Count)
            .ToList();
    }

    private async Task<IReadOnlyList<BulkDeleteBurstDto>> GetBulkDeleteBurstsAsync(
        int? marketId, DateTime now, CancellationToken ct)
    {
        var since = now.AddMinutes(-BulkDeleteWindowMinutes);
        var query = _context.AuditLogs.AsNoTracking()
            .Where(a => a.Action == AuditActions.Delete
                     && a.CreatedAt >= since
                     && a.UserId != null);
        if (marketId.HasValue)
            query = query.Where(a => a.MarketId == marketId.Value);

        var rows = await query
            .Select(a => new { UserId = a.UserId!.Value, a.EntityType, a.CreatedAt })
            .ToListAsync(ct);

        var groups = rows
            .GroupBy(r => r.UserId)
            .Where(g => g.Count() >= BulkDeleteThreshold)
            .Select(g => new
            {
                UserId = g.Key,
                Count = g.Count(),
                FirstSeen = g.Min(x => x.CreatedAt),
                LastSeen = g.Max(x => x.CreatedAt),
                EntityTypes = g.Select(x => x.EntityType).Distinct().OrderBy(x => x).ToList(),
            })
            .ToList();

        // Look the actor names up in one round-trip rather than a per-group
        // join — there are usually a handful of flagged users, so a single
        // IN-clause is the cheapest correct shape.
        var ids = groups.Select(g => g.UserId).ToList();
        var userNames = ids.Count == 0
            ? new Dictionary<Guid, string>()
            : await _context.Users.AsNoTracking()
                .Where(u => ids.Contains(u.Id))
                .Select(u => new { u.Id, u.FullName })
                .ToDictionaryAsync(u => u.Id, u => u.FullName, ct);

        return groups
            .Select(g => new BulkDeleteBurstDto(
                g.UserId,
                userNames.GetValueOrDefault(g.UserId),
                g.Count, g.FirstSeen, g.LastSeen, g.EntityTypes))
            .OrderByDescending(b => b.Count)
            .ToList();
    }

    /// <summary>Pull the <c>username</c> field out of a LoginFailed payload.
    /// Defensive against malformed JSON — a bad payload (shouldn't happen with
    /// our writers, but a future bug shouldn't crash detection) just returns
    /// null and the row is skipped.</summary>
    private static string? TryExtractUsername(string payload)
    {
        if (string.IsNullOrEmpty(payload)) return null;
        try
        {
            using var doc = JsonDocument.Parse(payload);
            if (doc.RootElement.ValueKind == JsonValueKind.Object
                && doc.RootElement.TryGetProperty("username", out var u)
                && u.ValueKind == JsonValueKind.String)
            {
                return u.GetString();
            }
        }
        catch (JsonException)
        {
            // swallowed — bad payload doesn't crash detection.
        }
        return null;
    }
}
