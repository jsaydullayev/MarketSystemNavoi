using Microsoft.EntityFrameworkCore.Storage;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;
using MarketSystem.Infrastructure.Repositories;

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

        Branches = new BaseRepository<Branch>(context);
        Customers = new BaseRepository<Customer>(context);
        Users = new UserRepository(context);
        Products = new BaseRepository<Product>(context);
        BranchProducts = new BranchProductRepository(context);
        Sales = new SaleRepository(context);
        SaleItems = new BaseRepository<SaleItem>(context);
        Payments = new BaseRepository<Payment>(context);
        Debts = new BaseRepository<Debt>(context);
        Zakups = new BaseRepository<Zakup>(context);
        AuditLogs = new BaseRepository<AuditLog>(context);
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
