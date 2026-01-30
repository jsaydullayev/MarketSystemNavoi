using Microsoft.EntityFrameworkCore;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class BranchProductRepository : BaseRepository<BranchProduct>, IBranchProductRepository
{
    public BranchProductRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<BranchProduct?> GetByBranchAndProductAsync(
        Guid branchId,
        Guid productId,
        CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(bp => bp.Product)
            .FirstOrDefaultAsync(bp => bp.BranchId == branchId && bp.ProductId == productId, cancellationToken);
    }

    public async Task<IEnumerable<BranchProduct>> GetByBranchAsync(
        Guid branchId,
        CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(bp => bp.Product)
            .Where(bp => bp.BranchId == branchId)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<BranchProduct>> GetLowStockProductsAsync(
        Guid branchId,
        CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(bp => bp.Product)
            .Where(bp => bp.BranchId == branchId && bp.Quantity <= bp.MinThreshold)
            .ToListAsync(cancellationToken);
    }
}
