using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace MarketSystem.Domain.Interfaces;

/// <summary>
/// Abstraction over the EF Core DbContext so Application-layer services can be
/// unit-tested without a real PostgreSQL dependency. Implemented by
/// <c>MarketSystem.Infrastructure.Data.AppDbContext</c>.
///
/// Lives in Domain — both Application and Infrastructure depend on Domain, so
/// placing the interface here avoids a circular reference (Infrastructure must
/// implement <see cref="IAppDbContext"/> but cannot reference Application).
/// </summary>
public interface IAppDbContext
{
    DbSet<Customer> Customers { get; }
    DbSet<User> Users { get; }
    DbSet<Market> Markets { get; }
    DbSet<Product> Products { get; }
    DbSet<ProductCategory> ProductCategories { get; }
    DbSet<Sale> Sales { get; }
    DbSet<SaleItem> SaleItems { get; }
    DbSet<Payment> Payments { get; }
    DbSet<Debt> Debts { get; }
    DbSet<DebtAuditLog> DebtAuditLogs { get; }
    DbSet<Zakup> Zakups { get; }
    DbSet<AuditLog> AuditLogs { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<CashRegister> CashRegisters { get; }
    DbSet<CashWithdrawal> CashWithdrawals { get; }
    DbSet<RegistrationRequest> RegistrationRequests { get; }

    DatabaseFacade Database { get; }

    EntityEntry Entry(object entity);
    EntityEntry<TEntity> Entry<TEntity>(TEntity entity) where TEntity : class;

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
