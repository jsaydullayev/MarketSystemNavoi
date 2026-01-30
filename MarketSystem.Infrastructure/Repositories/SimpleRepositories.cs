using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class BranchRepository : BaseRepository<Branch>, IRepository<Branch>
{
    public BranchRepository(AppDbContext context) : base(context) { }
}

public class CustomerRepository : BaseRepository<Customer>, IRepository<Customer>
{
    public CustomerRepository(AppDbContext context) : base(context) { }
}

public class ProductRepository : BaseRepository<Product>, IRepository<Product>
{
    public ProductRepository(AppDbContext context) : base(context) { }
}

public class SaleItemRepository : BaseRepository<SaleItem>, IRepository<SaleItem>
{
    public SaleItemRepository(AppDbContext context) : base(context) { }
}

public class PaymentRepository : BaseRepository<Payment>, IRepository<Payment>
{
    public PaymentRepository(AppDbContext context) : base(context) { }
}

public class DebtRepository : BaseRepository<Debt>, IRepository<Debt>
{
    public DebtRepository(AppDbContext context) : base(context) { }
}

public class ZakupRepository : BaseRepository<Zakup>, IRepository<Zakup>
{
    public ZakupRepository(AppDbContext context) : base(context) { }
}

public class AuditLogRepository : BaseRepository<AuditLog>, IRepository<AuditLog>
{
    public AuditLogRepository(AppDbContext context) : base(context) { }
}
