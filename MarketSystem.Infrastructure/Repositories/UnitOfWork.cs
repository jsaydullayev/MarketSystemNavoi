using Microsoft.EntityFrameworkCore.Storage;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;
    private IDbContextTransaction? _transaction;
    private bool _disposed;

    public IRepository<Customer> Customers { get; }
    public IUserRepository Users { get; }
    public IRepository<Product> Products { get; }
    public IRepository<ProductCategory> ProductCategories { get; }  // ✅ NEW
    public ISaleRepository Sales { get; }
    public IRepository<SaleItem> SaleItems { get; }
    public IRepository<Payment> Payments { get; }
    public IRepository<Debt> Debts { get; }
    public IRepository<DebtAuditLog> DebtAuditLogs { get; }
    public IRepository<Zakup> Zakups { get; }
    public IRepository<AuditLog> AuditLogs { get; }
    public IRefreshTokenRepository RefreshTokens { get; }

    public UnitOfWork(AppDbContext context)
    {
        _context = context;

        Customers = new CustomerRepository(context);
        Users = new UserRepository(context);
        Products = new ProductRepository(context);
        ProductCategories = new Repository<ProductCategory>(context);  // ✅ NEW
        Sales = new SaleRepository(context);
        SaleItems = new SaleItemRepository(context);
        Payments = new PaymentRepository(context);
        Debts = new DebtRepository(context);
        DebtAuditLogs = new DebtAuditLogRepository(context);
        Zakups = new ZakupRepository(context);
        AuditLogs = new AuditLogRepository(context);
        RefreshTokens = new RefreshTokenRepository(context);
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        _transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
    }

    public async Task CommitTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction != null)
        {
            await _transaction.CommitAsync(cancellationToken);
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public async Task RollbackTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync(cancellationToken);
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed)
        {
            if (disposing)
            {
                _transaction?.Dispose();
                _context.Dispose();
            }

            _disposed = true;
        }
    }
}
