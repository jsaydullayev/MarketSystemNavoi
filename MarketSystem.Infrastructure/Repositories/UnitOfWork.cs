using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    // How many times to replay a transactional operation that lost an
    // optimistic-concurrency race (DbUpdateConcurrencyException). A single
    // user completing a sale fires several writes that collide on shared
    // xmin-tokened rows (the per-market CashRegister, the per-sale Debt, a
    // double-tapped Product); EnableRetryOnFailure does NOT classify these as
    // transient, so without this they surfaced to the user as HTTP 409. 3
    // attempts comfortably absorbs realistic contention.
    private const int MaxConcurrencyRetries = 3;

    private readonly AppDbContext _context;
    private readonly ILogger<UnitOfWork> _logger;
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
    public IRepository<Shift> Shifts { get; }
    public IRefreshTokenRepository RefreshTokens { get; }

    public UnitOfWork(AppDbContext context, ILogger<UnitOfWork> logger)
    {
        _context = context;
        _logger = logger;

        Customers = new CustomerRepository(context);
        Users = new UserRepository(context);
        Products = new ProductRepository(context);
        ProductCategories = new ProductCategoryRepository(context);  // ✅ NEW
        Sales = new SaleRepository(context);
        SaleItems = new SaleItemRepository(context);
        Payments = new PaymentRepository(context);
        Debts = new DebtRepository(context);
        DebtAuditLogs = new DebtAuditLogRepository(context);
        Zakups = new ZakupRepository(context);
        AuditLogs = new AuditLogRepository(context);
        Shifts = new ShiftRepository(context);
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

    public async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        return await Microsoft.EntityFrameworkCore.ExecutionStrategyExtensions.ExecuteAsync(
            strategy,
            async () =>
            {
                for (var attempt = 1; ; attempt++)
                {
                    await BeginTransactionAsync(cancellationToken);
                    try
                    {
                        var result = await operation();
                        await CommitTransactionAsync(cancellationToken);
                        return result;
                    }
                    catch (DbUpdateConcurrencyException ex) when (attempt < MaxConcurrencyRetries)
                    {
                        // A concurrent writer bumped an xmin token (busy-sale
                        // CashRegister/Debt/Product, or a real multi-user race).
                        // Roll back, discard the now-stale tracked entities so
                        // the replay reads fresh from the DB, and re-run the
                        // whole operation. The operation delegates load their
                        // entities INSIDE the closure, so a replay re-reads.
                        _logger.LogWarning(ex,
                            "UnitOfWork: concurrency conflict, retrying (attempt {Attempt}/{Max}).",
                            attempt, MaxConcurrencyRetries);
                        await RollbackTransactionAsync(cancellationToken);
                        _context.ChangeTracker.Clear();
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "UnitOfWork: transaction rolled back.");
                        await RollbackTransactionAsync(cancellationToken);
                        throw;
                    }
                }
            });
    }

    public async Task ExecuteInTransactionAsync(Func<Task> operation, CancellationToken cancellationToken = default)
    {
        // Delegate to the generic overload so the concurrency-retry logic lives
        // in exactly one place.
        await ExecuteInTransactionAsync<object?>(async () =>
        {
            await operation();
            return null;
        }, cancellationToken);
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
                // Only dispose the transaction we own. AppDbContext is
                // registered separately as Scoped and DI owns its lifetime —
                // disposing it here causes a second dispose at scope end and,
                // worse, kills the context while other scoped components in
                // the same request may still be using it (K3 in the security
                // audit).
                _transaction?.Dispose();
            }

            _disposed = true;
        }
    }
}
