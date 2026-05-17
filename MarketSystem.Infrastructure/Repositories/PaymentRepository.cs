using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class PaymentRepository : BaseRepository<Payment>, IRepository<Payment>
{
    public PaymentRepository(AppDbContext context) : base(context) { }
}
