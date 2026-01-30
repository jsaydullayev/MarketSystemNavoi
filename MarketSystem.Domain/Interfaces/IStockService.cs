using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IStockService
{
    Task<bool> CheckStockAvailabilityAsync(Guid productId, Guid branchId, decimal quantity, CancellationToken cancellationToken = default);
    Task DeductStockAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task RestoreStockAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task<BranchProduct?> GetBranchProductAsync(Guid productId, Guid branchId, CancellationToken cancellationToken = default);
}
