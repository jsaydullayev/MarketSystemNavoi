using Microsoft.EntityFrameworkCore;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class SaleRepository : BaseRepository<Sale>, ISaleRepository
{
    public SaleRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Sale?> GetWithItemsAsync(Guid saleId, int marketId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.SaleItems)
            .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);
    }

    public async Task<Sale?> GetWithDetailsAsync(Guid saleId, int marketId, CancellationToken cancellationToken = default)
    {
        // Sale.Seller is a REQUIRED navigation, so Include(s => s.Seller) INNER-JOINs
        // User and enforces its `!IsDeleted` global filter — a sale whose seller was
        // soft-deleted would return null (a phantom 404). IgnoreQueryFilters() lifts
        // ALL global filters, so re-apply Sale's own soft-delete guard by hand.
        return await _dbSet
            .IgnoreQueryFilters()
            .Where(s => !s.IsDeleted)
            .Include(s => s.SaleItems)
            .Include(s => s.Payments)
            .Include(s => s.Debt)
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);
    }
}
