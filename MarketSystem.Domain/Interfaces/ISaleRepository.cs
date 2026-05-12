using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Interfaces;

public interface ISaleRepository : IRepository<Sale>
{
    /// <summary>
    /// Loads a sale by id with its SaleItems eagerly included.
    /// <paramref name="marketId"/> is required — callers must scope to the
    /// caller's tenant rather than relying on after-the-fact filtering.
    /// </summary>
    Task<Sale?> GetWithItemsAsync(Guid saleId, int marketId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads a sale by id with SaleItems, Payments, Debt, Seller, Customer eagerly included.
    /// Always tenant-scoped — see <see cref="GetWithItemsAsync"/>.
    /// </summary>
    Task<Sale?> GetWithDetailsAsync(Guid saleId, int marketId, CancellationToken cancellationToken = default);
}
