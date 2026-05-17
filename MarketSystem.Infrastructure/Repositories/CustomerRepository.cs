using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class CustomerRepository : BaseRepository<Customer>, IRepository<Customer>
{
    public CustomerRepository(AppDbContext context) : base(context) { }
}
