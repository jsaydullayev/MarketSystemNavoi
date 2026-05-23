using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface ICashRegisterService
{
    Task<CashRegisterDto?> GetCashRegisterAsync(CancellationToken cancellationToken = default);
    Task<bool> WithdrawCashAsync(WithdrawCashRequest request, Guid userId, CancellationToken cancellationToken = default);
    /// <summary>
    /// Add cash to the till. Y3 — <paramref name="userId"/> is the JWT-extracted
    /// caller identity (the controller pulls it from ClaimTypes.NameIdentifier).
    /// Logged as the actor on the resulting audit row so deposits are as
    /// accountable as withdrawals are.
    /// </summary>
    Task<bool> AddCashAsync(decimal amount, Guid userId, CancellationToken cancellationToken = default);
    Task<TodaySalesSummaryDto?> GetTodaySalesSummaryAsync(CancellationToken cancellationToken = default);
}
