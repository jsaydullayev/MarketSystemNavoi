using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class ProductCategoryRepository : BaseRepository<ProductCategory>, IRepository<ProductCategory>
{
    public ProductCategoryRepository(AppDbContext context) : base(context) { }
}
