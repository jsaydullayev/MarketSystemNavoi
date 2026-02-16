using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class DebtAuditLogRepository : BaseRepository<DebtAuditLog>
{
    public DebtAuditLogRepository(AppDbContext context) : base(context)
    {
    }
}
