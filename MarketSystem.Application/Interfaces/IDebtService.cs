using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Interfaces;

public interface IDebtService
{
    /// <summary>Open debts belonging to a single customer, tenant-scoped.</summary>
    Task<IEnumerable<DebtDto>> GetByCustomerAsync(Guid customerId, CancellationToken cancellationToken = default);

    /// <summary>Sum of every open debt for the customer, tenant-scoped.</summary>
    Task<decimal> GetCustomerTotalAsync(Guid customerId, CancellationToken cancellationToken = default);

    /// <summary>
    /// All debts in the current market. Optional filter by Status; result is
    /// ordered newest-first for the SuperAdmin / Owner debt console.
    /// </summary>
    Task<IEnumerable<DebtDto>> ListAsync(DebtStatus? status, CancellationToken cancellationToken = default);

    /// <summary>
    /// Record a payment against an open debt. Atomic: creates a Payment row,
    /// updates the debt + parent Sale, and adjusts the per-market CashRegister
    /// for cash payments.
    /// </summary>
    Task<PayDebtResultDto> PayAsync(Guid debtId, PayDebtDto request, Guid actorUserId, CancellationToken cancellationToken = default);
}

public record PayDebtResultDto(
    decimal RemainingDebt,
    decimal PaymentAmount,
    string DebtStatus
);
