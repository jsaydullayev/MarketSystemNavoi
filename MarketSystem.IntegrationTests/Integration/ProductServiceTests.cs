using MarketSystem.Application.DTOs;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// K6 — ProductService had zero direct tests. Covers the inventory-management
/// contract: lookup (single + paged), create (uniqueness, market scope, unit
/// validation), update, soft-delete, low-stock, and the per-market data
/// isolation the rest of the system depends on.
/// </summary>
public class ProductServiceTests : TestBase
{
    private ProductService CreateService()
    {
        // TestBase only mocks GetCurrentMarketId. CreateProduct (and a few
        // other paths) call TryGetCurrentMarketId instead — without this
        // local setup it would return null and the service throws
        // UnauthorizedAccessException.
        CurrentMarketServiceMock.Setup(x => x.TryGetCurrentMarketId()).Returns((int?)TestMarketId);
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new ProductService(unitOfWork, DbContext, CurrentMarketServiceMock.Object);
    }

    private Product SeedSampleProduct(string name = "Sample", decimal cost = 100m, decimal sale = 150m, decimal qty = 50m)
    {
        var p = new Product
        {
            Id = Guid.NewGuid(),
            Name = name,
            CostPrice = cost,
            SalePrice = sale,
            MinSalePrice = cost,
            Quantity = qty,
            MinThreshold = 5,
            Unit = UnitType.Piece,
            MarketId = TestMarketId,
            CreatedBySellerId = TestUserId,
        };
        DbContext.Products.Add(p);
        DbContext.SaveChanges();
        return p;
    }

    // ───────────────────── Lookup ─────────────────────

    [Fact]
    public async Task GetProductById_OwnMarket_ReturnsDto()
    {
        var seeded = SeedSampleProduct();
        var result = await CreateService().GetProductByIdAsync(seeded.Id);

        result.Should().NotBeNull();
        result!.Id.Should().Be(seeded.Id);
        result.Name.Should().Be("Sample");
    }

    [Fact]
    public async Task GetProductById_OtherMarket_ReturnsNull()
    {
        // Defensive multi-tenant isolation: a product in another market must
        // not be visible by Guid lookup.
        var otherMarketId = 9000;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "other", OwnerId = Guid.NewGuid() });
        var otherId = Guid.NewGuid();
        DbContext.Products.Add(new Product
        {
            Id = otherId,
            Name = "Foreign",
            CostPrice = 50,
            SalePrice = 100,
            MinSalePrice = 50,
            Quantity = 10,
            MinThreshold = 1,
            Unit = UnitType.Piece,
            MarketId = otherMarketId,
        });
        await DbContext.SaveChangesAsync();

        var result = await CreateService().GetProductByIdAsync(otherId);
        result.Should().BeNull();
    }

    [Fact]
    public async Task GetAllProducts_ReturnsOnlyCallersMarket()
    {
        SeedSampleProduct("InOurMarket");

        DbContext.Markets.Add(new Market { Id = 9001, Name = "X", Subdomain = "x", OwnerId = Guid.NewGuid() });
        DbContext.Products.Add(new Product
        {
            Id = Guid.NewGuid(),
            Name = "InOtherMarket",
            CostPrice = 10, SalePrice = 20, MinSalePrice = 10, Quantity = 5, MinThreshold = 1,
            Unit = UnitType.Piece, MarketId = 9001,
        });
        await DbContext.SaveChangesAsync();

        var products = (await CreateService().GetAllProductsAsync()).ToList();
        products.Should().OnlyContain(p => p.Name == "InOurMarket");
    }

    [Fact]
    public async Task GetLowStock_FiltersByMinThreshold()
    {
        // Two products in our market — only one is at/below its threshold.
        SeedSampleProduct("WellStocked", qty: 100m);
        var low = new Product
        {
            Id = Guid.NewGuid(),
            Name = "Low",
            CostPrice = 50, SalePrice = 80, MinSalePrice = 50,
            Quantity = 2, MinThreshold = 5,        // below threshold
            Unit = UnitType.Piece, MarketId = TestMarketId,
        };
        DbContext.Products.Add(low);
        await DbContext.SaveChangesAsync();

        var lowStock = (await CreateService().GetLowStockProductsAsync()).ToList();
        lowStock.Should().ContainSingle(p => p.Name == "Low");
    }

    // ───────────────────── Create ─────────────────────

    [Fact]
    public async Task CreateProduct_HappyPath_PersistsWithCallersMarketId()
    {
        var dto = new CreateProductDto(
            Name: "Yangi taxta",
            SalePrice: 200m,
            MinSalePrice: 150m,
            MinThreshold: 5,
            Unit: (int)UnitType.Piece,
            IsTemporary: false,
            CategoryId: null);

        var created = await CreateService().CreateProductAsync(dto, TestUserId);

        created.Should().NotBeNull();
        created.Name.Should().Be("Yangi taxta");

        ClearDbContext();
        var row = await DbContext.Products.FirstAsync(p => p.Id == created.Id);
        row.MarketId.Should().Be(TestMarketId);
        row.CreatedBySellerId.Should().Be(TestUserId);
    }

    [Fact]
    public async Task CreateProduct_DuplicateNameInSameMarket_Throws()
    {
        SeedSampleProduct("Mix");

        var dup = new CreateProductDto(
            Name: "Mix",
            SalePrice: 100m, MinSalePrice: 50m, MinThreshold: 1,
            Unit: (int)UnitType.Piece, IsTemporary: false, CategoryId: null);

        Func<Task> act = async () => await CreateService().CreateProductAsync(dup, TestUserId);
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*allaqachon mavjud*");
    }

    [Fact]
    public async Task CreateProduct_SameNameInDifferentMarket_Allowed()
    {
        // Per-market uniqueness — "Mix" in market A and "Mix" in market B must coexist.
        SeedSampleProduct("Mix");

        // Pretend the caller is now in a different market. Build the service
        // BEFORE switching the mock so CreateService doesn't re-set TestMarketId.
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        var service = new ProductService(unitOfWork, DbContext, CurrentMarketServiceMock.Object);

        var otherMarketId = 9002;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "other2", OwnerId = Guid.NewGuid() });
        await DbContext.SaveChangesAsync();
        CurrentMarketServiceMock.Setup(x => x.GetCurrentMarketId()).Returns(otherMarketId);
        CurrentMarketServiceMock.Setup(x => x.TryGetCurrentMarketId()).Returns((int?)otherMarketId);

        var dup = new CreateProductDto(
            Name: "Mix",
            SalePrice: 100m, MinSalePrice: 50m, MinThreshold: 1,
            Unit: (int)UnitType.Piece, IsTemporary: false, CategoryId: null);

        var created = await service.CreateProductAsync(dup, TestUserId);
        created.Should().NotBeNull();
        created.Name.Should().Be("Mix");
    }

    [Fact]
    public async Task CreateProduct_InvalidUnit_Throws()
    {
        var dto = new CreateProductDto(
            Name: "Bad",
            SalePrice: 100m, MinSalePrice: 50m, MinThreshold: 1,
            Unit: 999,         // outside UnitType enum
            IsTemporary: false, CategoryId: null);

        Func<Task> act = async () => await CreateService().CreateProductAsync(dto, TestUserId);
        await act.Should().ThrowAsync<ArgumentException>().WithMessage("*o'lchov*");
    }

    [Fact]
    public async Task CreateProduct_WithoutMarket_ThrowsUnauthorized()
    {
        // Build service first, then strip the market — otherwise the
        // CreateService helper re-sets TryGetCurrentMarketId to TestMarketId.
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        var service = new ProductService(unitOfWork, DbContext, CurrentMarketServiceMock.Object);

        CurrentMarketServiceMock.Setup(x => x.TryGetCurrentMarketId()).Returns((int?)null);

        var dto = new CreateProductDto(
            Name: "NoMarket",
            SalePrice: 100m, MinSalePrice: 50m, MinThreshold: 1,
            Unit: (int)UnitType.Piece, IsTemporary: false, CategoryId: null);

        Func<Task> act = async () => await service.CreateProductAsync(dto, TestUserId);
        await act.Should().ThrowAsync<UnauthorizedAccessException>();
    }

    // ───────────────────── Update / Delete ─────────────────────

    [Fact]
    public async Task UpdateProduct_OtherMarket_ReturnsNull_AndDoesNotMutate()
    {
        var otherMarketId = 9003;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "other3", OwnerId = Guid.NewGuid() });
        var otherProductId = Guid.NewGuid();
        DbContext.Products.Add(new Product
        {
            Id = otherProductId,
            Name = "Locked",
            CostPrice = 10, SalePrice = 20, MinSalePrice = 10,
            Quantity = 5, MinThreshold = 1, Unit = UnitType.Piece,
            MarketId = otherMarketId,
        });
        await DbContext.SaveChangesAsync();

        // Caller still on TestMarketId; attempt cross-tenant update.
        var upd = new UpdateProductDto(
            Id: otherProductId,
            Name: "Hijacked",
            SalePrice: 999m,
            MinSalePrice: 999m,
            MinThreshold: 1m,
            CategoryId: null,
            Unit: (int)UnitType.Piece,
            IsTemporary: false);
        var result = await CreateService().UpdateProductAsync(upd);

        result.Should().BeNull("cross-tenant update must be silently rejected");
        ClearDbContext();
        (await DbContext.Products.FirstAsync(p => p.Id == otherProductId))
            .Name.Should().Be("Locked");
    }

    [Fact]
    public async Task DeleteProduct_RemovesRow()
    {
        // Note: ProductService.DeleteProductAsync currently HARD-deletes
        // (Repository.Delete). Even though the Product entity implements
        // ISoftDelete, the service path doesn't honor it. Pinning the
        // current behavior so any future switch to soft-delete is a
        // conscious change.
        var seeded = SeedSampleProduct("ToDelete");
        var ok = await CreateService().DeleteProductAsync(seeded.Id);
        ok.Should().BeTrue();

        ClearDbContext();
        var exists = await DbContext.Products
            .IgnoreQueryFilters()
            .AnyAsync(p => p.Id == seeded.Id);
        exists.Should().BeFalse();
    }

    [Fact]
    public async Task DeleteProduct_OtherMarket_ReturnsFalse()
    {
        var otherMarketId = 9005;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "other5", OwnerId = Guid.NewGuid() });
        var otherId = Guid.NewGuid();
        DbContext.Products.Add(new Product
        {
            Id = otherId, Name = "Foreign",
            CostPrice = 10, SalePrice = 20, MinSalePrice = 10,
            Quantity = 5, MinThreshold = 1, Unit = UnitType.Piece,
            MarketId = otherMarketId,
        });
        await DbContext.SaveChangesAsync();

        var ok = await CreateService().DeleteProductAsync(otherId);
        ok.Should().BeFalse();

        ClearDbContext();
        var stillThere = await DbContext.Products.IgnoreQueryFilters().AnyAsync(p => p.Id == otherId);
        stillThere.Should().BeTrue();
    }

    // ───────────────────── Stock ─────────────────────

    [Fact]
    public async Task UpdateStock_AppliesDelta()
    {
        var seeded = SeedSampleProduct("Stock", qty: 50m);
        var ok = await CreateService().UpdateStockAsync(seeded.Id, 25m);
        ok.Should().BeTrue();

        ClearDbContext();
        var row = await DbContext.Products.FirstAsync(p => p.Id == seeded.Id);
        row.Quantity.Should().Be(75m);
    }

    [Fact]
    public async Task UpdateStock_OtherMarket_ReturnsFalse()
    {
        var otherMarketId = 9004;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "other4", OwnerId = Guid.NewGuid() });
        var otherId = Guid.NewGuid();
        DbContext.Products.Add(new Product
        {
            Id = otherId, Name = "X",
            CostPrice = 10, SalePrice = 20, MinSalePrice = 10,
            Quantity = 5, MinThreshold = 1, Unit = UnitType.Piece,
            MarketId = otherMarketId,
        });
        await DbContext.SaveChangesAsync();

        var ok = await CreateService().UpdateStockAsync(otherId, 999m);
        ok.Should().BeFalse();
    }
}
