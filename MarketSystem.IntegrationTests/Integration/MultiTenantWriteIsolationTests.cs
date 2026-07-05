using MarketSystem.Application.DTOs;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Companion to <see cref="MultiTenantIsolationTests"/>, which covers the
/// read paths (GetById / GetAll / phone lookup). This file closes the gaps the
/// audit flagged: the *write & mutation* paths and the services that weren't
/// exercised at all (Product, Zakup, ProductCategory, Debt).
///
/// The dangerous shape is always the same: <c>BaseRepository.GetByIdAsync(id)</c>
/// fetches by primary key with NO market filter, so the only thing standing
/// between an Owner of Market A and Market B's rows is each service method
/// remembering to scope by <c>MarketId</c>. These tests seed a sibling
/// "Market B", keep the caller pinned to "Market A" (the TestBase market), and
/// prove every mutating entry point either refuses the cross-tenant id
/// (null / false / throw) AND leaves Market B's data untouched.
/// </summary>
public class MultiTenantWriteIsolationTests : TestBase
{
    private const int OtherMarketId = 9999;
    private const int OtherCategoryId = 9001;

    private Guid _otherUserId;
    private Guid _otherCustomerId;
    private Guid _otherProductId;
    private Guid _otherSaleId;
    private Guid _otherZakupId;
    private Guid _otherDebtId;

    // Known seed values so "did the row change?" assertions are meaningful.
    private const decimal OtherProductQuantity = 100m;
    private const decimal OtherProductSalePrice = 150m;

    private async Task SeedOtherMarketAsync()
    {
        DbContext.Markets.Add(new Market
        {
            Id = OtherMarketId,
            Name = "Other Market",
            Subdomain = "other",
            OwnerId = Guid.NewGuid(),
        });

        _otherUserId = Guid.NewGuid();
        DbContext.Users.Add(new User
        {
            Id = _otherUserId,
            FullName = "Other Owner",
            Username = "other_owner",
            PasswordHash = "x",
            Role = Role.Owner,
            Language = Language.Uzbek,
            IsActive = true,
            MarketId = OtherMarketId,
        });

        _otherCustomerId = Guid.NewGuid();
        DbContext.Customers.Add(new Customer
        {
            Id = _otherCustomerId,
            FullName = "Other Customer",
            Phone = "+998999999999",
            Comment = "from another market",
            MarketId = OtherMarketId,
        });

        DbContext.ProductCategories.Add(new ProductCategory
        {
            Id = OtherCategoryId,
            Name = "Other Category",
            MarketId = OtherMarketId,
            IsActive = true,
        });

        _otherProductId = Guid.NewGuid();
        DbContext.Products.Add(new Product
        {
            Id = _otherProductId,
            Name = "Other Product",
            CostPrice = 100m,
            SalePrice = OtherProductSalePrice,
            MinSalePrice = 100m,
            Quantity = OtherProductQuantity,
            MinThreshold = 10,
            Unit = UnitType.Piece,
            CategoryId = null,
            CreatedBySellerId = _otherUserId,
            MarketId = OtherMarketId,
        });

        _otherSaleId = Guid.NewGuid();
        DbContext.Sales.Add(new Sale
        {
            Id = _otherSaleId,
            SellerId = _otherUserId,
            CustomerId = _otherCustomerId,
            TotalAmount = 50_000m,
            PaidAmount = 50_000m,
            Status = SaleStatus.Paid,
            MarketId = OtherMarketId,
        });

        _otherZakupId = Guid.NewGuid();
        DbContext.Zakups.Add(new Zakup
        {
            Id = _otherZakupId,
            ProductId = _otherProductId,
            Quantity = 10m,
            CostPrice = 100m,
            CreatedByAdminId = _otherUserId,
            MarketId = OtherMarketId,
        });

        // A debt (and its backing sale) wholly inside Market B, used to prove
        // a Market A caller can't pay down — or even see — Market B's debt.
        var otherDebtSaleId = Guid.NewGuid();
        DbContext.Sales.Add(new Sale
        {
            Id = otherDebtSaleId,
            SellerId = _otherUserId,
            CustomerId = _otherCustomerId,
            TotalAmount = 30_000m,
            PaidAmount = 0m,
            Status = SaleStatus.Debt,
            MarketId = OtherMarketId,
        });
        _otherDebtId = Guid.NewGuid();
        DbContext.Debts.Add(new Debt
        {
            Id = _otherDebtId,
            SaleId = otherDebtSaleId,
            CustomerId = _otherCustomerId,
            TotalDebt = 30_000m,
            RemainingDebt = 30_000m,
            Status = DebtStatus.Open,
            MarketId = OtherMarketId,
        });

        await DbContext.SaveChangesAsync();
        ClearDbContext();
    }

    // ─── Service factories (caller is always pinned to TestMarketId) ─────────

    private ProductService CreateProductService()
    {
        var uow = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new ProductService(uow, DbContext, CurrentMarketServiceMock.Object, new Moq.Mock<MarketSystem.Application.Interfaces.IProductImageStorage>().Object);
    }

    private ZakupService CreateZakupService()
    {
        var uow = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new ZakupService(uow, AuditLogServiceMock.Object, DbContext, CurrentMarketServiceMock.Object);
    }

    private ProductCategoryService CreateCategoryService()
    {
        var uow = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new ProductCategoryService(uow, CurrentMarketServiceMock.Object);
    }

    private DebtService CreateDebtService()
    {
        var uow = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new DebtService(DbContext, uow, CurrentMarketServiceMock.Object,
            AuditLogServiceMock.Object, NullLogger<DebtService>.Instance);
    }

    /// <summary>Seeds a Draft sale owned by the *caller's* market (Market A).</summary>
    private async Task<Guid> CreateOwnDraftSaleAsync()
    {
        var saleId = Guid.NewGuid();
        DbContext.Sales.Add(new Sale
        {
            Id = saleId,
            SellerId = TestUserId,
            CustomerId = null,
            TotalAmount = 0m,
            PaidAmount = 0m,
            Status = SaleStatus.Draft,
            MarketId = TestMarketId,
        });
        await DbContext.SaveChangesAsync();
        ClearDbContext();
        return saleId;
    }

    private async Task<Product> ReloadOtherProductAsync()
    {
        ClearDbContext();
        return await DbContext.Products
            .IgnoreQueryFilters()
            .FirstAsync(p => p.Id == _otherProductId);
    }

    // ─── ProductService ──────────────────────────────────────────────────

    [Fact]
    public async Task GetProductByIdAsync_OtherMarketProductId_ReturnsNull()
    {
        await SeedOtherMarketAsync();
        var products = CreateProductService();

        var result = await products.GetProductByIdAsync(_otherProductId);

        result.Should().BeNull("a product from another market must not be readable by Guid lookup");
    }

    [Fact]
    public async Task UpdateProductAsync_OtherMarketProductId_ReturnsNull_AndDoesNotMutate()
    {
        await SeedOtherMarketAsync();
        var products = CreateProductService();

        var result = await products.UpdateProductAsync(new UpdateProductDto(
            Id: _otherProductId,
            Name: "HACKED",
            SalePrice: 1m,
            MinSalePrice: 1m,
            MinThreshold: 0m,
            CategoryId: null));

        result.Should().BeNull("cross-tenant update must be rejected");
        var fresh = await ReloadOtherProductAsync();
        fresh.Name.Should().Be("Other Product");
        fresh.SalePrice.Should().Be(OtherProductSalePrice, "Market B's product must be untouched");
    }

    [Fact]
    public async Task DeleteProductAsync_OtherMarketProductId_ReturnsFalse_AndProductSurvives()
    {
        await SeedOtherMarketAsync();
        var products = CreateProductService();

        var ok = await products.DeleteProductAsync(_otherProductId);

        ok.Should().BeFalse("cross-tenant delete must be rejected silently");
        (await ReloadOtherProductAsync()).Should().NotBeNull("Market B's product must still exist");
    }

    [Fact]
    public async Task UpdateStockAsync_OtherMarketProductId_ReturnsFalse_AndQuantityUnchanged()
    {
        await SeedOtherMarketAsync();
        var products = CreateProductService();

        var ok = await products.UpdateStockAsync(_otherProductId, quantityChange: -999m);

        ok.Should().BeFalse("a Market A caller must not adjust Market B's stock");
        (await ReloadOtherProductAsync()).Quantity.Should().Be(OtherProductQuantity);
    }

    // ─── SaleService — write / mutation paths ─────────────────────────────

    [Fact]
    public async Task AddSaleItemAsync_OtherMarketProduct_IntoOwnDraftSale_Throws()
    {
        // The classic IDOR the audit flagged: the caller owns the sale, but
        // tries to line-item another market's product — which would leak that
        // product's name / cost / price into the response and the sale.
        await SeedOtherMarketAsync();
        var ownSaleId = await CreateOwnDraftSaleAsync();

        var act = async () => await SaleService.AddSaleItemAsync(ownSaleId, new AddSaleItemDto(
            IsExternal: false,
            ProductId: _otherProductId,
            ExternalProductName: null,
            ExternalCostPrice: null,
            Quantity: 1m,
            SalePrice: 150m,
            MinSalePrice: 100m,
            Comment: null));

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*does not belong to this market*");
    }

    [Fact]
    public async Task UpdateSaleCustomerAsync_AssignOtherMarketCustomer_ToOwnSale_Throws()
    {
        // Mirror IDOR: the sale is ours, but the customer we try to attach
        // belongs to Market B — it must be rejected, not silently linked.
        await SeedOtherMarketAsync();
        var ownSaleId = await CreateOwnDraftSaleAsync();

        var act = async () => await SaleService.UpdateSaleCustomerAsync(
            ownSaleId, new UpdateSaleCustomerDto(CustomerId: _otherCustomerId));

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task UpdateSaleCustomerAsync_OtherMarketSaleId_ReturnsNull()
    {
        await SeedOtherMarketAsync();

        var result = await SaleService.UpdateSaleCustomerAsync(
            _otherSaleId, new UpdateSaleCustomerDto(CustomerId: null));

        result.Should().BeNull("a sale from another market is not addressable");
    }

    [Fact]
    public async Task CancelSaleAsync_OtherMarketSaleId_ReturnsNull_AndSaleSurvives()
    {
        await SeedOtherMarketAsync();

        var result = await SaleService.CancelSaleAsync(_otherSaleId, TestUserId);

        result.Should().BeNull("cross-tenant cancel must be a no-op");
        ClearDbContext();
        var stillThere = await DbContext.Sales.IgnoreQueryFilters().FirstAsync(s => s.Id == _otherSaleId);
        stillThere.Status.Should().Be(SaleStatus.Paid, "Market B's sale must be unchanged");
    }

    [Fact]
    public async Task DeleteSaleAsync_OtherMarketSaleId_ReturnsNull_AndSaleSurvives()
    {
        await SeedOtherMarketAsync();

        var result = await SaleService.DeleteSaleAsync(_otherSaleId, TestUserId);

        result.Should().BeNull("cross-tenant delete must be a no-op");
        ClearDbContext();
        var stillThere = await DbContext.Sales.IgnoreQueryFilters().FirstAsync(s => s.Id == _otherSaleId);
        stillThere.IsDeleted.Should().BeFalse("Market B's sale must not be soft-deleted");
    }

    // ─── ZakupService ─────────────────────────────────────────────────────

    [Fact]
    public async Task GetZakupByIdAsync_OtherMarketZakupId_ReturnsNull()
    {
        await SeedOtherMarketAsync();
        var zakups = CreateZakupService();

        var result = await zakups.GetZakupByIdAsync(_otherZakupId);

        result.Should().BeNull();
    }

    [Fact]
    public async Task CreateZakupAsync_AgainstOtherMarketProduct_Throws()
    {
        // A purchase booked against another market's product would both leak
        // that product's existence and corrupt its stock/cost from outside.
        await SeedOtherMarketAsync();
        var zakups = CreateZakupService();

        var act = async () => await zakups.CreateZakupAsync(
            new CreateZakupDto(ProductId: _otherProductId, Quantity: 5m, CostPrice: 100m),
            adminId: TestUserId);

        await act.Should().ThrowAsync<InvalidOperationException>();
        // Market B's product stock must be exactly as seeded.
        (await ReloadOtherProductAsync()).Quantity.Should().Be(OtherProductQuantity);
    }

    // ─── ProductCategoryService ───────────────────────────────────────────

    [Fact]
    public async Task GetCategoryByIdAsync_OtherMarketCategoryId_ReturnsNull()
    {
        await SeedOtherMarketAsync();
        var categories = CreateCategoryService();

        var result = await categories.GetCategoryByIdAsync(OtherCategoryId);

        result.Should().BeNull();
    }

    [Fact]
    public async Task DeleteCategoryAsync_OtherMarketCategoryId_ReturnsFalse_AndCategorySurvives()
    {
        await SeedOtherMarketAsync();
        var categories = CreateCategoryService();

        var ok = await categories.DeleteCategoryAsync(OtherCategoryId);

        ok.Should().BeFalse("cross-tenant category delete must be rejected");
        ClearDbContext();
        var stillThere = await DbContext.ProductCategories
            .IgnoreQueryFilters()
            .FirstAsync(c => c.Id == OtherCategoryId);
        stillThere.IsDeleted.Should().BeFalse();
    }

    // ─── DebtService ──────────────────────────────────────────────────────

    [Fact]
    public async Task PayAsync_OtherMarketDebtId_Throws_AndDebtUnchanged()
    {
        // Paying a debt the caller can't see would move cash in Market B's
        // register and mutate Market B's debt — the guard returns the same
        // "not found" shape as a non-existent debt, revealing nothing.
        await SeedOtherMarketAsync();
        var debts = CreateDebtService();

        var act = async () => await debts.PayAsync(
            _otherDebtId, new PayDebtDto(Amount: 10_000m, PaymentType: "cash"), actorUserId: TestUserId);

        await act.Should().ThrowAsync<KeyNotFoundException>();
        ClearDbContext();
        var stillThere = await DbContext.Debts.IgnoreQueryFilters().FirstAsync(d => d.Id == _otherDebtId);
        stillThere.RemainingDebt.Should().Be(30_000m, "Market B's debt balance must be untouched");
        stillThere.Status.Should().Be(DebtStatus.Open);
    }
}
