using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface ICashRegisterService
{
    Task<CashRegisterDto?> GetCashRegisterAsync(CancellationToken cancellationToken = default);
    Task<bool> WithdrawCashAsync(WithdrawCashRequest request, Guid userId, CancellationToken cancellationToken = default);
    Task<bool> AddCashAsync(decimal amount, CancellationToken cancellationToken = default);
}
