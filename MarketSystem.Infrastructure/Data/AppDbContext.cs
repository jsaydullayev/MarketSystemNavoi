using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Infrastructure.Data;

public class AppDbContext : DbContext, IAppDbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Market> Markets => Set<Market>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductCategory> ProductCategories => Set<ProductCategory>();  // ✅ NEW
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
    public DbSet<RegistrationRequest> RegistrationRequests => Set<RegistrationRequest>();
    public DbSet<RevokedToken> RevokedTokens => Set<RevokedToken>();
    public DbSet<Shift> Shifts => Set<Shift>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure RevokedToken
        modelBuilder.Entity<RevokedToken>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Jti).IsRequired().HasMaxLength(200);
            b.HasIndex(x => x.Jti).IsUnique();
            b.HasIndex(x => x.ExpiresAtUtc);
        });

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

            // Block state — TenantResolutionMiddleware queries (Id, IsBlocked) on
            // every authenticated request, so cover both columns with a partial
            // index. The partial index keeps the on-disk size tiny because the
            // common case is `IsBlocked = false`.
            b.Property(x => x.IsBlocked).HasDefaultValue(false);
            b.Property(x => x.BlockedReason).HasMaxLength(500);
            b.HasIndex(x => new { x.Id, x.IsBlocked })
                .HasFilter("\"IsBlocked\" = TRUE")
                .HasDatabaseName("IX_Markets_Blocked");

            // Owner relationship
            b.HasOne(x => x.Owner).WithMany().HasForeignKey(x => x.OwnerId);
            b.HasIndex(x => x.OwnerId);
        });

        // Configure Customer
        modelBuilder.Entity<Customer>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Phone).IsRequired().HasMaxLength(20);
            b.Property(x => x.FullName).HasMaxLength(200);
            b.Property(x => x.Comment).HasMaxLength(500);
            b.HasQueryFilter(x => !x.IsDeleted);

            // Multi-tenancy
            b.HasOne(x => x.Market).WithMany(m => m.Customers).HasForeignKey(x => x.MarketId);
            b.HasIndex(x => x.MarketId);
            // Phone is unique per market — different markets can share customer phones.
            b.HasIndex(x => new { x.MarketId, x.Phone }).IsUnique();
        });

        // Configure User
        modelBuilder.Entity<User>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.FullName).IsRequired().HasMaxLength(200);
            b.Property(x => x.Username).IsRequired().HasMaxLength(100);
            b.Property(x => x.PasswordHash).IsRequired();
            b.Property(x => x.Phone).HasMaxLength(20);
            b.Property(x => x.Language).HasDefaultValue(Language.Uzbek).IsRequired();
            // ProfileImage stores base64 encoded image data - use TEXT type for unlimited size
            b.Property(x => x.ProfileImage).HasColumnType("text");
            // Owner RBAC — explicit permission set as a PostgreSQL text[] array.
            // Npgsql maps List<string> to text[] natively; default is an empty array.
            b.Property(x => x.Permissions)
                .HasColumnType("text[]")
                .HasDefaultValueSql("'{}'::text[]");
            b.HasQueryFilter(x => !x.IsDeleted);

            // Multi-tenancy
            b.HasOne(x => x.Market).WithMany(m => m.Users).HasForeignKey(x => x.MarketId);
            b.HasIndex(x => x.MarketId);
            // Username scope:
            //   - Tenant users (MarketId IS NOT NULL): unique per market.
            //   - Cross-tenant users (MarketId IS NULL, e.g. SuperAdmin): globally unique.
            b.HasIndex(x => new { x.MarketId, x.Username })
                .IsUnique()
                .HasFilter("\"MarketId\" IS NOT NULL")
                .HasDatabaseName("IX_Users_MarketId_Username_Unique");
            b.HasIndex(x => x.Username)
                .IsUnique()
                .HasFilter("\"MarketId\" IS NULL")
                .HasDatabaseName("IX_Users_Username_GlobalUnique");
        });

        // Configure Product
        modelBuilder.Entity<Product>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Name).IsRequired().HasMaxLength(200);
            b.Property(x => x.CostPrice).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.SalePrice).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.MinSalePrice).HasPrecision(18, 2).IsRequired();
            b.Property(x => x.Quantity).HasPrecision(18, 3).IsRequired();
            b.Property(x => x.MinThreshold).HasPrecision(18, 3).IsRequired();

            // Optimistic concurrency via PostgreSQL system column xmin.
            b.Property(x => x.Xmin)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            // ✅ Category relationship (optional)
            b.HasOne(x => x.Category).WithMany(c => c.Products).HasForeignKey(x => x.CategoryId);

            b.HasOne(x => x.CreatedBySeller).WithMany(p => p.TemporaryProducts).HasForeignKey(x => x.CreatedBySellerId);
            b.HasOne(x => x.Market).WithMany(m => m.Products).HasForeignKey(x => x.MarketId);
            b.HasQueryFilter(x => !x.IsDeleted);
            b.HasIndex(x => x.MarketId);
            b.HasIndex(x => x.CategoryId);  // ✅ Index for faster filtering
            // Product name is unique per market. Partial index excludes
            // soft-deleted rows so re-adding a product after delete works.
            b.HasIndex(x => new { x.MarketId, x.Name })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false")
                .HasDatabaseName("IX_Products_MarketId_Name_Active");
        });

        // ✅ Configure ProductCategory
        modelBuilder.Entity<ProductCategory>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Id).ValueGeneratedOnAdd();
            b.Property(x => x.Name).IsRequired().HasMaxLength(100);
            b.Property(x => x.Description).HasMaxLength(500);
            b.Property(x => x.Icon).HasMaxLength(32);  // Single emoji glyph (ZWJ sequences fit in 32)
            b.Property(x => x.MarketId).IsRequired();  // ✅ NOT NULL - required
            b.Property(x => x.IsActive).IsRequired();
            b.Property(x => x.CreatedAt).IsRequired();
            b.Property(x => x.UpdatedAt).IsRequired();
            b.Property(x => x.IsDeleted).IsRequired();
            b.Property(x => x.DeletedAt).IsRequired(false);

            // Multi-tenancy - Market foreign key (no navigation property needed)
            b.HasIndex(x => x.MarketId);
            b.HasIndex(x => x.Name);  // ✅ Index for searching by name
            b.HasQueryFilter(x => !x.IsDeleted);

            // ✅ Navigation property
            b.HasMany(x => x.Products).WithOne(p => p.Category).HasForeignKey(x => x.CategoryId)
                .OnDelete(DeleteBehavior.SetNull);  // ✅ Category o'chirilsa, Product.CategoryId = NULL
        });

        // Configure Sale
        modelBuilder.Entity<Sale>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.TotalAmount).HasPrecision(18, 2);
            b.Property(x => x.PaidAmount).HasPrecision(18, 2);

            // Optimistic concurrency via PostgreSQL system column xmin.
            // No DDL needed — xmin already exists on every PostgreSQL table.
            b.Property(x => x.Xmin)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            // IMPORTANT: Seller/User o'chirilsa, Sale tarixi o'CHMASIN kerak
            b.HasOne(x => x.Seller).WithMany(p => p.Sales).HasForeignKey(x => x.SellerId)
                .OnDelete(DeleteBehavior.Restrict);

            // IMPORTANT: Customer o'chirilsa, Sale tarixi o'CHMASIN kerak
            b.HasOne(x => x.Customer).WithMany(p => p.Sales).HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

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

            // ✅ IsExternal - mandatory, default false
            b.Property(x => x.IsExternal)
                .IsRequired()
                .HasDefaultValue(false);

            // ✅ ProductId - nullable bo'lishi mumkin
            b.Property(x => x.ProductId)
                .IsRequired(false);  // Nullable FK

            // ✅ ExternalProductName - nullable bo'lishi mumkin
            b.Property(x => x.ExternalProductName)
                .HasMaxLength(200)
                .IsRequired(false);

            // ✅ ExternalCostPrice - default 0
            b.Property(x => x.ExternalCostPrice)
                .HasPrecision(18, 2)
                .HasDefaultValue(0m);

            b.Property(x => x.Quantity).HasPrecision(18, 3).IsRequired();
            b.Property(x => x.CostPrice).HasPrecision(18, 2);
            b.Property(x => x.SalePrice).HasPrecision(18, 2);
            b.Property(x => x.Comment).HasMaxLength(500);

            b.HasOne(x => x.Sale).WithMany(p => p.SaleItems).HasForeignKey(x => x.SaleId)
                .OnDelete(DeleteBehavior.Cascade); // Sale o'chirilsa, SaleItemlar ham o'chadi

            // ✅ Product relationship - nullable FK bo'lishi mumkin
            // IMPORTANT: Product o'chirilganda SaleItemlar o'CHMASIN kerak (tarix saqlash uchun)
            b.HasOne(x => x.Product).WithMany(p => p.SaleItems).HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Restrict); // Product o'chirilsa, SaleItemlar qoladi

            // Index for performance
            b.HasIndex(x => new { x.SaleId, x.ProductId })
                .HasDatabaseName("IX_SaleItem_Sale_Product");
        });

        // Configure Payment
        modelBuilder.Entity<Payment>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.Amount).HasPrecision(18, 2);

            b.HasOne(x => x.Sale).WithMany(p => p.Payments).HasForeignKey(x => x.SaleId)
                .OnDelete(DeleteBehavior.Cascade); // Sale o'chirilsa, Paymentlar ham o'chadi

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

            b.HasOne(x => x.Sale).WithOne(x => x.Debt).HasForeignKey<Debt>(x => x.SaleId)
                .OnDelete(DeleteBehavior.Cascade); // Sale o'chirilsa, Debt ham o'chadi

            // IMPORTANT: Customer o'chirilsa, Debt tarixi o'CHMASIN kerak
            b.HasOne(x => x.Customer).WithMany(p => p.Debts).HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.Market).WithMany(m => m.Debts).HasForeignKey(x => x.MarketId);

            // Index for performance
            b.HasIndex(x => new { x.CustomerId, x.Status })
                .HasDatabaseName("IX_Debt_Customer_Status");
            b.HasIndex(x => x.MarketId);
            b.HasIndex(x => x.SaleId)
                .HasDatabaseName("IX_Debt_SaleId");
        });

        // Configure Shift — seller work sessions
        modelBuilder.Entity<Shift>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.OpenedAt).IsRequired();

            b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict); // keep shift history if a user is removed
            b.HasOne(x => x.Market).WithMany().HasForeignKey(x => x.MarketId);

            b.HasIndex(x => x.MarketId);
            // Fast "is there an open shift for this user" lookup.
            b.HasIndex(x => new { x.UserId, x.ClosedAt });
        });

        // Configure DebtAuditLog
        modelBuilder.Entity<DebtAuditLog>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.OldPrice).HasPrecision(18, 2);
            b.Property(x => x.NewPrice).HasPrecision(18, 2);
            b.Property(x => x.Comment).IsRequired().HasMaxLength(500);

            // IMPORTANT: Audit log tarixi hech qachon o'CHMASIN kerak
            b.HasOne(x => x.Sale).WithMany().HasForeignKey(x => x.SaleId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.SaleItem).WithMany().HasForeignKey(x => x.SaleItemId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.ChangedByUser).WithMany().HasForeignKey(x => x.ChangedByUserId)
                .OnDelete(DeleteBehavior.Restrict); // User o'chirilsa, audit log qoladi

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

            // IMPORTANT: Product o'chirilganda Zakup tarixi o'CHMASIN kerak
            b.HasOne(x => x.Product).WithMany(p => p.Zakups).HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Restrict);

            b.HasOne(x => x.CreatedByAdmin).WithMany(p => p.Zakups).HasForeignKey(x => x.CreatedByAdminId)
                .OnDelete(DeleteBehavior.Restrict); // User o'chirilsa, Zakup tarixi qoladi

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
            b.Property(x => x.IpAddress).HasMaxLength(64);

            // IMPORTANT: Audit log tarixi hech qachon o'CHMASIN kerak
            b.HasOne(x => x.User).WithMany(p => p.AuditLogs).HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.Market).WithMany().HasForeignKey(x => x.MarketId)
                .OnDelete(DeleteBehavior.SetNull);

            // Indexes for performance
            b.HasIndex(x => new { x.EntityType, x.EntityId, x.CreatedAt })
                .HasDatabaseName("IX_AuditLog_Entity_CreatedAt");
            b.HasIndex(x => new { x.UserId, x.CreatedAt })
                .HasDatabaseName("IX_AuditLog_User_CreatedAt");
            b.HasIndex(x => x.MarketId)
                .HasDatabaseName("IX_AuditLog_MarketId");
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

            // Multi-tenancy: each Market has exactly one CashRegister.
            b.Property(x => x.MarketId).IsRequired();
            b.HasOne(x => x.Market).WithOne(m => m.CashRegister).HasForeignKey<CashRegister>(x => x.MarketId);
            b.HasIndex(x => x.MarketId).IsUnique();
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

        // Configure RegistrationRequest
        modelBuilder.Entity<RegistrationRequest>(b =>
        {
            b.HasKey(x => x.Id);
            b.Property(x => x.FullName).IsRequired().HasMaxLength(200);
            b.Property(x => x.Phone).IsRequired().HasMaxLength(20);
            b.Property(x => x.Status).IsRequired();
            b.Property(x => x.CreatedAt).IsRequired();
            b.Property(x => x.RejectReason).HasMaxLength(500);

            // Optimistic concurrency via PostgreSQL system column xmin.
            // Surfaces concurrent approvals as DbUpdateConcurrencyException → 409.
            b.Property(x => x.Xmin)
                .HasColumnName("xmin")
                .HasColumnType("xid")
                .ValueGeneratedOnAddOrUpdate()
                .IsConcurrencyToken();

            // SuperAdmin lists are typically filtered by Status and ordered by date.
            b.HasIndex(x => x.Status);
            b.HasIndex(x => x.CreatedAt);
            // Partial unique on Phone WHERE Status=Pending (0) prevents two parallel
            // submissions from a single phone landing as duplicate pending rows.
            // Rejected/Approved rows from the same phone are allowed — the applicant
            // can re-apply after a rejection.
            b.HasIndex(x => x.Phone)
                .IsUnique()
                .HasFilter("\"Status\" = 0")
                .HasDatabaseName("IX_RegistrationRequests_Phone_Pending");

            // Linkage to the artifacts we create on approval. Use Restrict so a user
            // can't be cascade-deleted while a historical request still references it.
            b.HasOne(x => x.ProcessedByUser).WithMany().HasForeignKey(x => x.ProcessedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.CreatedUser).WithMany().HasForeignKey(x => x.CreatedUserId)
                .OnDelete(DeleteBehavior.Restrict);
            b.HasOne(x => x.CreatedMarket).WithMany().HasForeignKey(x => x.CreatedMarketId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
