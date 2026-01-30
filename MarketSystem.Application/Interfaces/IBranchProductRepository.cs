using MarketSystem.Domain.Entities;

namespace MarketSystem.Application.Interfaces;

public interface IBranchProductRepository : IRepository<BranchProduct>
{
    Task<BranchProduct?> GetByBranchAndProductAsync(Guid branchId, Guid productId, CancellationToken cancellationToken = default);
    Task<IEnumerable<BranchProduct>> GetByBranchAsync(Guid branchId, CancellationToken cancellationToken = default);
    Task<IEnumerable<BranchProduct>> GetLowStockProductsAsync(Guid branchId, CancellationToken cancellationToken = default);
}
