using System.Text.Json;
using MarketSystem.Application.DTOs;
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
            var auditLog = new AuditLog
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
        CancellationToken cancellationToken = default)
    {
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
}
