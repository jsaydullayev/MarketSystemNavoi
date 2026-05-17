using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class SaleItemRepository : BaseRepository<SaleItem>, IRepository<SaleItem>
{
    public SaleItemRepository(AppDbContext context) : base(context) { }
}
