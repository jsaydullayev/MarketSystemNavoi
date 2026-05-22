using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

/// <inheritdoc cref="IShiftService"/>
public class ShiftService : IShiftService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IAuditLogService _auditLogService;

    public ShiftService(
        IUnitOfWork unitOfWork,
        ICurrentMarketService currentMarketService,
        IAuditLogService auditLogService)
    {
        _unitOfWork = unitOfWork;
        _currentMarketService = currentMarketService;
        _auditLogService = auditLogService;
    }

    public async Task<ShiftDto?> GetCurrentShiftAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var open = await FindOpenShiftAsync(userId, cancellationToken);
        return open is null ? null : ToDto(open);
    }

    public async Task<ShiftDto> OpenShiftAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        // Idempotent — re-opening an already-open shift returns it unchanged so
        // a double-tap on the client doesn't create overlapping sessions.
        var existing = await FindOpenShiftAsync(userId, cancellationToken);
        if (existing is not null)
            return ToDto(existing);

        var shift = new Shift
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            MarketId = _currentMarketService.GetCurrentMarketId(),
            OpenedAt = DateTime.UtcNow,
        };
        await _unitOfWork.Shifts.AddAsync(shift, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.Shift, shift.Id, AuditActions.Open, userId,
            new { shift.OpenedAt }, cancellationToken);

        return ToDto(shift);
    }

    public async Task<ShiftDto> CloseShiftAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var open = await FindOpenShiftAsync(userId, cancellationToken)
            ?? throw new InvalidOperationException("Ochiq smena topilmadi.");

        open.ClosedAt = DateTime.UtcNow;
        _unitOfWork.Shifts.Update(open);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.Shift, open.Id, AuditActions.Close, userId,
            new { open.OpenedAt, open.ClosedAt, open.DurationMinutes }, cancellationToken);

        return ToDto(open);
    }

    /// <summary>The user's single open shift in the current market, if any.</summary>
    private async Task<Shift?> FindOpenShiftAsync(Guid userId, CancellationToken cancellationToken)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var shifts = await _unitOfWork.Shifts.FindAsync(
            s => s.UserId == userId && s.MarketId == marketId && s.ClosedAt == null,
            cancellationToken);
        return shifts.FirstOrDefault();
    }

    private static ShiftDto ToDto(Shift s) =>
        new(s.Id, s.UserId, s.OpenedAt, s.ClosedAt, s.IsOpen, s.DurationMinutes);
}
