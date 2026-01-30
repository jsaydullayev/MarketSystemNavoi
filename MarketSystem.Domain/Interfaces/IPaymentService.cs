using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Interfaces;

public interface IPaymentService
{
    Task<Payment> AddPaymentAsync(Guid saleId, PaymentType paymentType, decimal amount, CancellationToken cancellationToken = default);
    Task UpdateSaleStatusAsync(Sale sale, CancellationToken cancellationToken = default);
    Task<Debt?> CreateOrUpdateDebtAsync(Sale sale, CancellationToken cancellationToken = default);
    Task CloseDebtAsync(Guid saleId, CancellationToken cancellationToken = default);
}
