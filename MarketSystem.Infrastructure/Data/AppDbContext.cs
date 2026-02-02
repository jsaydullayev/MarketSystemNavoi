using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Sale> Sales => Set<Sale>();
    public DbSet<SaleItem> SaleItems => Set<SaleItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Debt> Debts => Set<Debt>();
    public DbSet<Zakup> Zakups => Set<Zakup>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure Customer
        modelBuilder.Entity<Customer>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Phone).IsRequired().HasMaxLength(20);
            b.HasIndex(x => x.Phone).IsUnique();
            b.Property(x => x.FullName).HasMaxLength(200);
            b.HasQueryFilter(x => !x.IsDeleted);
        });

        // Configure User
        modelBuilder.Entity<User>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.FullName).IsRequired().HasMaxLength(200);
            b.Property(x => x.Username).IsRequired().HasMaxLength(100);
            b.Property(x => x.PasswordHash).IsRequired();
            b.HasIndex(x => x.Username).IsUnique();
        });

        // Configure Product
        modelBuilder.Entity<Product>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Name).IsRequired().HasMaxLength(200);
            b.Property(x => x.CostPrice).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.SalePrice).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.MinSalePrice).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.Quantity).IsRequired();
            b.Property(x => x.MinThreshold).IsRequired();

            b.HasOne(x => x.CreatedBySeller).WithMany(p => p.TemporaryProducts).HasForeignKey(x => x.CreatedBySellerId);
        });

        // Configure Sale
        modelBuilder.Entity<Sale>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.TotalAmount).HasPrecision(18, 2);
            b.Property(x => x.PaidAmount).HasPrecision(18, 2);

            b.HasOne(x => x.Seller).WithMany(p => p.Sales).HasForeignKey(x => x.SellerId);
            b.HasOne(x => x.Customer).WithMany(p => p.Sales).HasForeignKey(x => x.CustomerId);

            b.HasOne(x => x.Debt).WithOne(x => x.Sale).HasForeignKey<Debt>(x => x.SaleId);
        });

        // Configure SaleItem
        modelBuilder.Entity<SaleItem>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Quantity).IsRequired();
            b.Property(x => x.CostPrice).HasPrecision(18, 2);
            b.Property(x => x.SalePrice).HasPrecision(18, 2);
            b.Property(x => x.Comment).HasMaxLength(500);

            b.HasOne(x => x.Sale).WithMany(p => p.SaleItems).HasForeignKey(x => x.SaleId);
            b.HasOne(x => x.Product).WithMany(p => p.SaleItems).HasForeignKey(x => x.ProductId);
        });

        // Configure Payment
        modelBuilder.Entity<Payment>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Amount).HasPrecision(18, 2);

            b.HasOne(x => x.Sale).WithMany(p => p.Payments).HasForeignKey(x => x.SaleId);
        });

        // Configure Debt
        modelBuilder.Entity<Debt>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.TotalDebt).HasPrecision(18, 2);
            b.Property(x => x.RemainingDebt).HasPrecision(18, 2);

            b.HasOne(x => x.Sale).WithOne(x => x.Debt).HasForeignKey<Debt>(x => x.SaleId);
            b.HasOne(x => x.Customer).WithMany(p => p.Debts).HasForeignKey(x => x.CustomerId);
        });

        // Configure Zakup
        modelBuilder.Entity<Zakup>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Quantity).HasPrecision(18, 3);
            b.Property(x => x.CostPrice).HasPrecision(18, 2);

            b.HasOne(x => x.Product).WithMany(p => p.Zakups).HasForeignKey(x => x.ProductId);
            b.HasOne(x => x.CreatedByAdmin).WithMany(p => p.Zakups).HasForeignKey(x => x.CreatedByAdminId);
        });

        // Configure AuditLog
        modelBuilder.Entity<AuditLog>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.EntityType).IsRequired().HasMaxLength(100);
            b.Property(x => x.Action).IsRequired().HasMaxLength(50);
            b.Property(x => x.Payload);

            b.HasOne(x => x.User).WithMany(p => p.AuditLogs).HasForeignKey(x => x.UserId);
        });

        // Configure RefreshToken
        modelBuilder.Entity<RefreshToken>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Token).IsRequired().HasMaxLength(500);
            b.Property(x => x.ExpiresAt).IsRequired();
            b.Property(x => x.IsUsed).IsRequired();
            b.Property(x => x.IsRevoked).IsRequired();

            b.HasOne(x => x.User).WithMany(p => p.RefreshTokens).HasForeignKey(x => x.UserId);
        });
    }
}
