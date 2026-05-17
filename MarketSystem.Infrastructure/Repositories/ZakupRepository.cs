using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class ZakupRepository : BaseRepository<Zakup>, IRepository<Zakup>
{
    public ZakupRepository(AppDbContext context) : base(context) { }
}
