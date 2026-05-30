using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Abstraction over the EF Core DbContext so Application-layer services can be
/// unit-tested without a real PostgreSQL dependency. Implemented by
/// <c>MarketSystem.Infrastructure.Data.AppDbContext</c>.
///
/// K4 — Previously lived in Domain, which forced Domain to take a hard
/// dependency on Microsoft.EntityFrameworkCore. Moved to Application so that
/// Domain stays a pure model layer (Clean Architecture). Infrastructure
/// already references Application, so the contract still has a single
/// implementer with no circular references.
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
    DbSet<RevokedToken> RevokedTokens { get; }
    DbSet<LoginAttempt> LoginAttempts { get; }
    DbSet<Shift> Shifts { get; }

    DatabaseFacade Database { get; }

    EntityEntry Entry(object entity);
    EntityEntry<TEntity> Entry<TEntity>(TEntity entity) where TEntity : class;

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
