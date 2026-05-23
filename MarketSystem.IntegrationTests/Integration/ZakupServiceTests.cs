using MarketSystem.Application.DTOs;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// K6 — ZakupService had zero direct tests. This is the path that mutates
/// product cost+stock based on a purchase (zakup) — the audit summary called
/// it out because financial / stock mistakes here are silent. Pins:
///   • CreateZakup updates Product.Quantity and Product.CostPrice correctly
///   • CreateZakup rejects unknown products
///   • Cross-tenant product Ids are silently rejected (no leak)
///   • Each zakup write produces an audit row
/// </summary>
public class ZakupServiceTests : TestBase
{
    private ZakupService CreateService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new ZakupService(unitOfWork, AuditLogServiceMock.Object, DbContext, CurrentMarketServiceMock.Object);
    }

    private Product SeedProduct(string name = "Sample", decimal cost = 100m, decimal qty = 50m, int? marketId = null)
    {
        var p = new Product
        {
            Id = Guid.NewGuid(),
            Name = name,
            CostPrice = cost,
            SalePrice = cost * 1.5m,
            MinSalePrice = cost,
            Quantity = qty,
            MinThreshold = 5,
            Unit = UnitType.Piece,
            MarketId = marketId ?? TestMarketId,
            CreatedBySellerId = TestUserId,
        };
        DbContext.Products.Add(p);
        DbContext.SaveChanges();
        return p;
    }

    // ───────────────────── Create ─────────────────────

    [Fact]
    public async Task CreateZakup_UpdatesProductStockAndCost()
    {
        // Seed product at cost=100, qty=50. A zakup of 20@150 should
        // bump qty to 70 and update the cost basis to 150 (latest purchase).
        var product = SeedProduct(cost: 100m, qty: 50m);

        var dto = new CreateZakupDto(product.Id, 20m, 150m);
        var zakup = await CreateService().CreateZakupAsync(dto, TestUserId);

        zakup.Should().NotBeNull();
        zakup.Quantity.Should().Be(20m);
        zakup.CostPrice.Should().Be(150m);

        ClearDbContext();
        var updated = await DbContext.Products.FirstAsync(p => p.Id == product.Id);
        updated.Quantity.Should().Be(70m, "stock = old qty + zakup qty");
        updated.CostPrice.Should().Be(150m, "cost basis = latest zakup price");
    }

    [Fact]
    public async Task CreateZakup_WritesAuditRow()
    {
        var product = SeedProduct();
        var dto = new CreateZakupDto(product.Id, 5m, 200m);

        await CreateService().CreateZakupAsync(dto, TestUserId);

        AuditLogServiceMock.Verify(x => x.LogZakupActionAsync(
            It.IsAny<Guid>(), TestUserId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateZakup_UnknownProduct_Throws()
    {
        var dto = new CreateZakupDto(Guid.NewGuid(), 5m, 200m);

        Func<Task> act = async () => await CreateService().CreateZakupAsync(dto, TestUserId);
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*not found*");
    }

    [Fact]
    public async Task CreateZakup_ProductInOtherMarket_RejectedSilently()
    {
        // Defensive multi-tenant isolation — a caller in market A must NOT
        // be able to mutate a product that belongs to market B by passing
        // its Guid.
        var otherMarketId = 9100;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "z-other", OwnerId = Guid.NewGuid() });
        await DbContext.SaveChangesAsync();
        var foreign = SeedProduct("Foreign", cost: 50m, qty: 10m, marketId: otherMarketId);

        var dto = new CreateZakupDto(foreign.Id, 99m, 999m);

        Func<Task> act = async () => await CreateService().CreateZakupAsync(dto, TestUserId);
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*not found*");

        ClearDbContext();
        var untouched = await DbContext.Products.FirstAsync(p => p.Id == foreign.Id);
        untouched.Quantity.Should().Be(10m);
        untouched.CostPrice.Should().Be(50m);
    }

    // ───────────────────── Lookup ─────────────────────

    [Fact]
    public async Task GetZakupById_OwnMarket_ReturnsDto()
    {
        var product = SeedProduct();
        var dto = new CreateZakupDto(product.Id, 5m, 200m);
        var created = await CreateService().CreateZakupAsync(dto, TestUserId);

        var fetched = await CreateService().GetZakupByIdAsync(created.Id);
        fetched.Should().NotBeNull();
        fetched!.Id.Should().Be(created.Id);
        fetched.Quantity.Should().Be(5m);
        fetched.CostPrice.Should().Be(200m);
    }

    [Fact]
    public async Task GetZakupById_OtherMarket_ReturnsNull()
    {
        // Seed a Zakup in another market and confirm caller in TestMarket
        // can't retrieve it.
        var otherMarketId = 9101;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "z-other2", OwnerId = Guid.NewGuid() });
        var foreignProduct = SeedProduct("ForeignSample", cost: 60m, qty: 20m, marketId: otherMarketId);
        var foreignZakupId = Guid.NewGuid();
        DbContext.Zakups.Add(new Zakup
        {
            Id = foreignZakupId,
            ProductId = foreignProduct.Id,
            Quantity = 5,
            CostPrice = 100,
            CreatedByAdminId = Guid.NewGuid(),
            MarketId = otherMarketId,
        });
        await DbContext.SaveChangesAsync();

        var fetched = await CreateService().GetZakupByIdAsync(foreignZakupId);
        fetched.Should().BeNull();
    }

    [Fact]
    public async Task GetAllZakups_ReturnsOnlyCallersMarket()
    {
        var mine = SeedProduct("Mine");
        await CreateService().CreateZakupAsync(new CreateZakupDto(mine.Id, 5m, 100m), TestUserId);

        // Foreign zakup row
        var otherMarketId = 9102;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "z-other3", OwnerId = Guid.NewGuid() });
        var foreignProduct = SeedProduct("Foreign", cost: 60m, qty: 20m, marketId: otherMarketId);
        DbContext.Zakups.Add(new Zakup
        {
            Id = Guid.NewGuid(),
            ProductId = foreignProduct.Id,
            Quantity = 10,
            CostPrice = 80,
            CreatedByAdminId = Guid.NewGuid(),
            MarketId = otherMarketId,
        });
        await DbContext.SaveChangesAsync();

        var zakups = (await CreateService().GetAllZakupsAsync()).ToList();
        zakups.Should().OnlyContain(z => z.ProductName == "Mine",
            "zakups from another market must not leak");
    }
}
