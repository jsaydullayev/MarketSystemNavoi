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

    /// <summary>
    /// P6 — stage an audit row on the shared DbContext without saving. The
    /// caller's next <c>SaveChangesAsync</c> batches the audit INSERT with the
    /// business write, eliminating one round trip per hot operation. Audit row
    /// will commit/rollback with the surrounding business transaction. Use
    /// <see cref="LogActionAsync"/> instead when you want fire-and-forget
    /// semantics (errors swallowed, separate save).
    /// </summary>
    Task EnqueueActionAsync(
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
