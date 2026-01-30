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

    public IRepository<Branch> Branches { get; }
    public IRepository<Customer> Customers { get; }
    public IUserRepository Users { get; }
    public IRepository<Product> Products { get; }
    public IBranchProductRepository BranchProducts { get; }
    public ISaleRepository Sales { get; }
    public IRepository<SaleItem> SaleItems { get; }
    public IRepository<Payment> Payments { get; }
    public IRepository<Debt> Debts { get; }
    public IRepository<Zakup> Zakups { get; }
    public IRepository<AuditLog> AuditLogs { get; }

    public UnitOfWork(AppDbContext context)
    {
        _context = context;

        Branches = new BranchRepository(context);
        Customers = new CustomerRepository(context);
        Users = new UserRepository(context);
        Products = new ProductRepository(context);
        BranchProducts = new BranchProductRepository(context);
        Sales = new SaleRepository(context);
        SaleItems = new SaleItemRepository(context);
        Payments = new PaymentRepository(context);
        Debts = new DebtRepository(context);
        Zakups = new ZakupRepository(context);
        AuditLogs = new AuditLogRepository(context);
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
