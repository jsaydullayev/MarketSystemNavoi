using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class DebtRepository : BaseRepository<Debt>, IRepository<Debt>
{
    public DebtRepository(AppDbContext context) : base(context) { }
}
