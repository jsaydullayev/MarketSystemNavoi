using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Interfaces;

public interface ISaleRepository : IRepository<Sale>
{
    Task<Sale?> GetWithItemsAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task<Sale?> GetWithDetailsAsync(Guid saleId, CancellationToken cancellationToken = default);
}
