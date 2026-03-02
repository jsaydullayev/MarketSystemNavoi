using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Base class for integration tests with common setup
/// </summary>
public abstract class TestBase : IDisposable
{
    protected AppDbContext DbContext { get; private set; } = null!;
    protected ServiceProvider ServiceProvider { get; private set; } = null!;
    protected Mock<ILogger<SaleService>> SaleServiceLoggerMock { get; private set; } = null!;
    protected Mock<ILogger<CashRegisterService>> CashRegisterServiceLoggerMock { get; private set; } = null!;
    protected Mock<ICurrentMarketService> CurrentMarketServiceMock { get; private set; } = null!;
    protected Mock<IAuditLogService> AuditLogServiceMock { get; private set; } = null!;

    // Services
    protected SaleService SaleService { get; private set; } = null!;
    protected CashRegisterService CashRegisterService { get; private set; } = null!;
    protected CustomerService CustomerService { get; private set; } = null!;

    // Test data
    protected int TestMarketId { get; private set; }
    protected Guid TestUserId { get; private set; }
    protected User TestUser { get; private set; } = null!;
    protected Market TestMarket { get; private set; } = null!;
    protected Customer TestCustomer { get; private set; } = null!;

    private static int _nextMarketId = 1;

    protected TestBase()
    {
        TestMarketId = _nextMarketId++;
        TestUserId = Guid.NewGuid();
        SetupTestEnvironment();
    }

    private void SetupTestEnvironment()
    {
        var services = new ServiceCollection();

        // In-memory database
        services.AddDbContext<AppDbContext>(options =>
        {
            options.UseInMemoryDatabase(databaseName: $"MarketSystemTest_{Guid.NewGuid()}");
            options.EnableSensitiveDataLogging();
            options.EnableDetailedErrors();
        });

        // Mocks
        SaleServiceLoggerMock = new Mock<ILogger<SaleService>>();
        CashRegisterServiceLoggerMock = new Mock<ILogger<CashRegisterService>>();
        CurrentMarketServiceMock = new Mock<ICurrentMarketService>();
        AuditLogServiceMock = new Mock<IAuditLogService>();
        var httpContextAccessorMock = new Mock<IHttpContextAccessor>();

        // Setup current market service
        CurrentMarketServiceMock.Setup(x => x.GetCurrentMarketId()).Returns(TestMarketId);

        // Register services
        services.AddScoped(_ => SaleServiceLoggerMock.Object);
        services.AddScoped(_ => CashRegisterServiceLoggerMock.Object);
        services.AddScoped(_ => CurrentMarketServiceMock.Object);
        services.AddScoped(_ => AuditLogServiceMock.Object);

        ServiceProvider = services.BuildServiceProvider();

        // Initialize database
        DbContext = ServiceProvider.GetRequiredService<AppDbContext>();
        DbContext.Database.EnsureCreated();

        // Initialize services with UnitOfWork
        var unitOfWork = new Infrastructure.Repositories.UnitOfWork(DbContext);
        CustomerService = new CustomerService(unitOfWork, DbContext, CurrentMarketServiceMock.Object, httpContextAccessorMock.Object);
        SaleService = new SaleService(unitOfWork, AuditLogServiceMock.Object, DbContext, SaleServiceLoggerMock.Object, CurrentMarketServiceMock.Object, CustomerService);
        CashRegisterService = new CashRegisterService(unitOfWork, CashRegisterServiceLoggerMock.Object, DbContext, CurrentMarketServiceMock.Object);

        // Seed test data
        SeedTestData();
    }

    private void SeedTestData()
    {
        // Create test market
        TestMarket = new Market
        {
            Id = TestMarketId,
            Name = "Test Market",
            Subdomain = "test",
            OwnerId = TestUserId
        };
        DbContext.Markets.Add(TestMarket);

        // Create test user
        TestUser = new User
        {
            Id = TestUserId,
            FullName = "Test User",
            Username = "testuser",
            PasswordHash = "hashedpassword",
            Language = Language.Uzbek,
            MarketId = TestMarketId
        };
        DbContext.Users.Add(TestUser);

        // Create test customer
        TestCustomer = new Customer
        {
            Id = Guid.NewGuid(),
            FullName = "Test Customer",
            Phone = "+998901234567",
            Comment = "Test customer",
            MarketId = TestMarketId
        };
        DbContext.Customers.Add(TestCustomer);

        // Create test cash register
        var cashRegister = new CashRegister
        {
            Id = Guid.NewGuid(),
            CurrentBalance = 0,
            LastUpdated = DateTime.UtcNow
        };
        DbContext.CashRegisters.Add(cashRegister);

        DbContext.SaveChanges();
    }

    protected Product CreateTestProduct(decimal costPrice = 100m, decimal salePrice = 150m)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = "Test Product",
            CostPrice = costPrice,
            SalePrice = salePrice,
            MinSalePrice = costPrice,
            Quantity = 100,
            MinThreshold = 10,
            Unit = UnitType.Piece,
            CategoryId = null,
            CreatedBySellerId = TestUserId,
            MarketId = TestMarketId
        };
        DbContext.Products.Add(product);
        DbContext.SaveChanges();
        return product;
    }

    protected async Task<Sale> CreateTestSaleAsync(decimal totalAmount, decimal paidAmount, bool isDebt = false)
    {
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = TestUserId,
            CustomerId = TestCustomer.Id,
            TotalAmount = totalAmount,
            PaidAmount = paidAmount,
            Status = isDebt ? SaleStatus.Debt : SaleStatus.Paid,
            MarketId = TestMarketId
        };

        DbContext.Sales.Add(sale);
        await DbContext.SaveChangesAsync();

        // If debt, create debt record
        if (isDebt)
        {
            var debt = new Debt
            {
                Id = Guid.NewGuid(),
                SaleId = sale.Id,
                CustomerId = TestCustomer.Id,
                TotalDebt = totalAmount,
                RemainingDebt = totalAmount - paidAmount,
                Status = DebtStatus.Open,
                MarketId = TestMarketId
            };
            DbContext.Debts.Add(debt);
            await DbContext.SaveChangesAsync();
        }

        return sale;
    }

    protected async Task<Sale> CreateSaleWithItemsAsync(decimal totalAmount, decimal paidAmount, List<(Guid productId, decimal quantity, decimal price)> items, bool isDebt = false)
    {
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = TestUserId,
            CustomerId = TestCustomer.Id,
            TotalAmount = totalAmount,
            PaidAmount = paidAmount,
            Status = isDebt ? SaleStatus.Debt : SaleStatus.Paid,
            MarketId = TestMarketId
        };

        foreach (var item in items)
        {
            var saleItem = new SaleItem
            {
                Id = Guid.NewGuid(),
                SaleId = sale.Id,
                ProductId = item.productId,
                Quantity = item.quantity,
                CostPrice = 100m, // Default cost price
                SalePrice = item.price,
                Comment = ""
            };
            DbContext.SaleItems.Add(saleItem);
        }

        DbContext.Sales.Add(sale);
        await DbContext.SaveChangesAsync();

        // If debt, create debt record
        if (isDebt)
        {
            var debt = new Debt
            {
                Id = Guid.NewGuid(),
                SaleId = sale.Id,
                CustomerId = TestCustomer.Id,
                TotalDebt = totalAmount,
                RemainingDebt = totalAmount - paidAmount,
                Status = DebtStatus.Open,
                MarketId = TestMarketId
            };
            DbContext.Debts.Add(debt);
            await DbContext.SaveChangesAsync();
        }

        return sale;
    }

    public virtual void Dispose()
    {
        DbContext?.Database?.EnsureDeleted();
        DbContext?.Dispose();
        ServiceProvider?.Dispose();
    }

    protected void ClearDbContext()
    {
        var entries = DbContext.ChangeTracker.Entries().ToList();
        foreach (var entry in entries)
        {
            entry.State = EntityState.Detached;
        }
    }
}
