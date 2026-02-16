using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Market> Markets => Set<Market>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Sale> Sales => Set<Sale>();
    public DbSet<SaleItem> SaleItems => Set<SaleItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Debt> Debts => Set<Debt>();
    public DbSet<DebtAuditLog> DebtAuditLogs => Set<DebtAuditLog>();
    public DbSet<Zakup> Zakups => Set<Zakup>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<CashRegister> CashRegisters => Set<CashRegister>();
    public DbSet<CashWithdrawal> CashWithdrawals => Set<CashWithdrawal>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure Market
        modelBuilder.Entity<Market>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Id).ValueGeneratedOnAdd();
            b.Property(x => x.Name).IsRequired().HasMaxLength(200);
            b.Property(x => x.Subdomain).HasMaxLength(100);
            b.Property(x => x.Description).HasMaxLength(500);
            b.HasIndex(x => x.Subdomain).IsUnique();
            b.HasIndex(x => x.Name).IsUnique();  // Market nomi unikal bo'lishi kerak

            // Owner relationship
            b.HasOne(x => x.Owner).WithMany().HasForeignKey(x => x.OwnerId);
            b.HasIndex(x => x.OwnerId);
        });

        // Configure Customer
        modelBuilder.Entity<Customer>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Phone).IsRequired().HasMaxLength(20);
            b.HasIndex(x => x.Phone).IsUnique();
            b.Property(x => x.FullName).HasMaxLength(200);
            b.Property(x => x.Comment).HasMaxLength(500);
            b.HasQueryFilter(x => !x.IsDeleted);

            // Multi-tenancy
            b.HasOne(x => x.Market).WithMany(m => m.Customers).HasForeignKey(x => x.MarketId);
            b.HasIndex(x => x.MarketId);
        });

        // Configure User
        modelBuilder.Entity<User>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.FullName).IsRequired().HasMaxLength(200);
            b.Property(x => x.Username).IsRequired().HasMaxLength(100);
            b.Property(x => x.PasswordHash).IsRequired();
            b.Property(x => x.Language).HasDefaultValue(Language.Uzbek).IsRequired();
            // ProfileImage stores base64 encoded image data - use TEXT type for unlimited size
            b.Property(x => x.ProfileImage).HasColumnType("text");
            b.HasIndex(x => x.Username).IsUnique();
            b.HasQueryFilter(x => !x.IsDeleted);

            // Multi-tenancy
            b.HasOne(x => x.Market).WithMany(m => m.Users).HasForeignKey(x => x.MarketId);
            b.HasIndex(x => x.MarketId);
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
            b.HasOne(x => x.Market).WithMany(m => m.Products).HasForeignKey(x => x.MarketId);
            b.HasQueryFilter(x => !x.IsDeleted);
            b.HasIndex(x => x.MarketId);
        });

        // Configure Sale
        modelBuilder.Entity<Sale>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.TotalAmount).HasPrecision(18, 2);
            b.Property(x => x.PaidAmount).HasPrecision(18, 2);

            b.HasOne(x => x.Seller).WithMany(p => p.Sales).HasForeignKey(x => x.SellerId);
            b.HasOne(x => x.Customer).WithMany(p => p.Sales).HasForeignKey(x => x.CustomerId);
            b.HasOne(x => x.Market).WithMany(m => m.Sales).HasForeignKey(x => x.MarketId);

            b.HasOne(x => x.Debt).WithOne(x => x.Sale).HasForeignKey<Debt>(x => x.SaleId);

            // Indexes for performance
            b.HasIndex(x => new { x.Status, x.CreatedAt })
                .HasDatabaseName("IX_Sale_Status_CreatedAt");
            b.HasIndex(x => x.CustomerId)
                .HasDatabaseName("IX_Sale_CustomerId");
            b.HasIndex(x => new { x.SellerId, x.Status })
                .HasDatabaseName("IX_Sale_Seller_Status");
            b.HasIndex(x => x.MarketId);

            // Soft delete filter
            b.HasQueryFilter(x => !x.IsDeleted);
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

            // Index for performance
            b.HasIndex(x => new { x.SaleId, x.ProductId })
                .HasDatabaseName("IX_SaleItem_Sale_Product");
        });

        // Configure Payment
        modelBuilder.Entity<Payment>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Amount).HasPrecision(18, 2);

            b.HasOne(x => x.Sale).WithMany(p => p.Payments).HasForeignKey(x => x.SaleId);
            b.HasOne(x => x.Market).WithMany().HasForeignKey(x => x.MarketId);

            // Index for performance
            b.HasIndex(x => x.SaleId)
                .HasDatabaseName("IX_Payment_SaleId");
            b.HasIndex(x => x.MarketId);
        });

        // Configure Debt
        modelBuilder.Entity<Debt>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.TotalDebt).HasPrecision(18, 2);
            b.Property(x => x.RemainingDebt).HasPrecision(18, 2);

            b.HasOne(x => x.Sale).WithOne(x => x.Debt).HasForeignKey<Debt>(x => x.SaleId);
            b.HasOne(x => x.Customer).WithMany(p => p.Debts).HasForeignKey(x => x.CustomerId);
            b.HasOne(x => x.Market).WithMany(m => m.Debts).HasForeignKey(x => x.MarketId);

            // Index for performance
            b.HasIndex(x => new { x.CustomerId, x.Status })
                .HasDatabaseName("IX_Debt_Customer_Status");
            b.HasIndex(x => x.MarketId);
        });

        // Configure DebtAuditLog
        modelBuilder.Entity<DebtAuditLog>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.OldPrice).HasPrecision(18, 2);
            b.Property(x => x.NewPrice).HasPrecision(18, 2);
            b.Property(x => x.Comment).IsRequired().HasMaxLength(500);

            b.HasOne(x => x.Sale).WithMany().HasForeignKey(x => x.SaleId);
            b.HasOne(x => x.SaleItem).WithMany().HasForeignKey(x => x.SaleItemId);
            b.HasOne(x => x.ChangedByUser).WithMany().HasForeignKey(x => x.ChangedByUserId);
            b.HasOne(x => x.Market).WithMany().HasForeignKey(x => x.MarketId);

            // Indexes for performance
            b.HasIndex(x => new { x.SaleId, x.CreatedAt })
                .HasDatabaseName("IX_DebtAuditLog_Sale_CreatedAt");
            b.HasIndex(x => new { x.SaleItemId, x.CreatedAt })
                .HasDatabaseName("IX_DebtAuditLog_SaleItem_CreatedAt");
            b.HasIndex(x => x.ChangedByUserId)
                .HasDatabaseName("IX_DebtAuditLog_ChangedBy");
            b.HasIndex(x => x.MarketId);
        });

        // Configure Zakup
        modelBuilder.Entity<Zakup>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Quantity).HasPrecision(18, 3);
            b.Property(x => x.CostPrice).HasPrecision(18, 2);

            b.HasOne(x => x.Product).WithMany(p => p.Zakups).HasForeignKey(x => x.ProductId);
            b.HasOne(x => x.CreatedByAdmin).WithMany(p => p.Zakups).HasForeignKey(x => x.CreatedByAdminId);
            b.HasOne(x => x.Market).WithMany(m => m.Zakups).HasForeignKey(x => x.MarketId);
            b.HasIndex(x => x.MarketId);
        });

        // Configure AuditLog
        modelBuilder.Entity<AuditLog>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.EntityType).IsRequired().HasMaxLength(100);
            b.Property(x => x.Action).IsRequired().HasMaxLength(50);
            b.Property(x => x.Payload);

            b.HasOne(x => x.User).WithMany(p => p.AuditLogs).HasForeignKey(x => x.UserId);

            // Indexes for performance
            b.HasIndex(x => new { x.EntityType, x.EntityId, x.CreatedAt })
                .HasDatabaseName("IX_AuditLog_Entity_CreatedAt");
            b.HasIndex(x => new { x.UserId, x.CreatedAt })
                .HasDatabaseName("IX_AuditLog_User_CreatedAt");
        });

        // Configure RefreshToken
        modelBuilder.Entity<RefreshToken>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Token).IsRequired().HasMaxLength(500);
            b.Property(x => x.ExpiresAt).IsRequired();
            b.Property(x => x.IsUsed).IsRequired();
            b.Property(x => x.IsRevoked).IsRequired();

            // Indexes for performance
            b.HasIndex(x => x.Token)
                .HasDatabaseName("IX_RefreshToken_Token");
            b.HasIndex(x => new { x.UserId, x.ExpiresAt })
                .HasDatabaseName("IX_RefreshToken_User_ExpiresAt");
        });

        // Configure CashRegister
        modelBuilder.Entity<CashRegister>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.CurrentBalance).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.LastUpdated).IsRequired();
            b.HasIndex(x => x.LastUpdated);

            // NOTE: Multi-tenancy disabled for CashRegister
            // b.HasOne(x => x.Market).WithMany(m => m.CashRegisters).HasForeignKey(x => x.MarketId);
            // b.HasIndex(x => x.MarketId);
        });

        // Configure CashWithdrawal
        modelBuilder.Entity<CashWithdrawal>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Amount).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.Comment).IsRequired().HasMaxLength(500);
            b.Property(x => x.WithdrawalDate).IsRequired();

            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
            b.HasIndex(x => x.WithdrawalDate);
        });
    }
}
