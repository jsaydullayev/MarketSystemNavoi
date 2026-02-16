using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IRepository<Customer> Customers { get; }
    IUserRepository Users { get; }
    IRepository<Product> Products { get; }
    ISaleRepository Sales { get; }
    IRepository<SaleItem> SaleItems { get; }
    IRepository<Payment> Payments { get; }
    IRepository<Debt> Debts { get; }
    IRepository<DebtAuditLog> DebtAuditLogs { get; }
    IRepository<Zakup> Zakups { get; }
    IRepository<AuditLog> AuditLogs { get; }
    IRefreshTokenRepository RefreshTokens { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync(CancellationToken cancellationToken = default);
    Task CommitTransactionAsync(CancellationToken cancellationToken = default);
    Task RollbackTransactionAsync(CancellationToken cancellationToken = default);
}
