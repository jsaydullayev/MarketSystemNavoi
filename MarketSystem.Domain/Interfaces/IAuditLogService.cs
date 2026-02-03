using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IAuditLogService
{
    Task LogActionAsync(
        string entityType,
        Guid entityId,
        string action,
        Guid userId,
        object? payload = null,
        CancellationToken cancellationToken = default);

    Task LogSaleActionAsync(Guid saleId, string action, Guid userId, CancellationToken cancellationToken = default);
    Task LogPaymentActionAsync(Guid paymentId, Guid userId, CancellationToken cancellationToken = default);
    Task LogZakupActionAsync(Guid zakupId, Guid userId, CancellationToken cancellationToken = default);
    Task LogDebtActionAsync(Guid debtId, string action, Guid userId, CancellationToken cancellationToken = default);
}
