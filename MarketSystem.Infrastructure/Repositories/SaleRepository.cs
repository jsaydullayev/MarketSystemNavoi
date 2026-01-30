using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class SaleRepository : BaseRepository<Sale>, ISaleRepository
{
    public SaleRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Sale?> GetWithItemsAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.SaleItems)
            .FirstOrDefaultAsync(s => s.Id == saleId, cancellationToken);
    }

    public async Task<Sale?> GetWithDetailsAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.SaleItems).ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Include(s => s.Debt)
            .Include(s => s.Seller)
            .Include(s => s.Branch)
            .Include(s => s.Customer)
            .FirstOrDefaultAsync(s => s.Id == saleId, cancellationToken);
    }

    public async Task<IEnumerable<Sale>> GetDraftSalesByBranchAsync(
        Guid branchId,
        CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.SaleItems).ThenInclude(si => si.Product)
            .Include(s => s.Seller)
            .Where(s => s.BranchId == branchId && s.Status == SaleStatus.Draft)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<Sale>> GetSalesByBranchAsync(
        Guid branchId,
        DateTime startDate,
        DateTime endDate,
        CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.SaleItems).ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.BranchId == branchId
                && s.CreatedAt >= startDate
                && s.CreatedAt <= endDate
                && s.Status != SaleStatus.Cancelled)
            .ToListAsync(cancellationToken);
    }
}
