using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class AuditLogRepository : BaseRepository<AuditLog>, IRepository<AuditLog>
{
    public AuditLogRepository(AppDbContext context) : base(context) { }
}
