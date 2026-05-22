using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class ShiftRepository : BaseRepository<Shift>
{
    public ShiftRepository(AppDbContext context) : base(context)
    {
    }
}
