using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class ProductRepository : BaseRepository<Product>, IRepository<Product>
{
    public ProductRepository(AppDbContext context) : base(context) { }
}
