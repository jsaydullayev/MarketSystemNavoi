using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Application layer abstraction over EF Core DbContext.
/// Removes the direct dependency on AppDbContext (Infrastructure) from all Application services,
/// satisfying the Dependency Inversion Principle.
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

    DatabaseFacade Database { get; }

    EntityEntry<TEntity> Entry<TEntity>(TEntity entity) where TEntity : class;

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
