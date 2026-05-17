using FluentAssertions;
using MarketSystem.Application.DTOs;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Tashqi mahsulot (IsExternal=true) uchun integration testlar.
/// Backend logikasini smoke test qiladi: stok o'zgarmasligi, foyda hisoblanishi,
/// validatsiyalar (cost >= sale narx rad etilishi), va birlashtirish (bir xil
/// nomli tashqi mahsulot ikki marta qo'shilsa quantity yig'ilishi).
/// </summary>
public class ExternalProductIntegrationTests : TestBase
{
    [Fact]
    public async Task AddExternalItem_ShouldNotChangeProductStock()
    {
        // Arrange: oddiy mahsulot (stok 100) va bo'sh sotuv
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var initialStock = product.Quantity;

        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(TestCustomer.Id), TestUserId);

        // Act: TASHQI mahsulot qo'shamiz
        var externalRequest = new AddSaleItemDto(
            IsExternal: true,
            ProductId: null,
            ExternalProductName: "Qo'shnidan olingan tovar",
            ExternalCostPrice: 5000m,
            Quantity: 3,
            SalePrice: 7000m,
            MinSalePrice: 0m,
            Comment: null
        );

        var result = await SaleService.AddSaleItemAsync(sale!.Id, externalRequest);

        // Assert
        ClearDbContext();

        // SaleItem yaratildi va IsExternal=true
        var saleItem = await DbContext.SaleItems.FirstAsync(si => si.SaleId == sale.Id);
        saleItem.IsExternal.Should().BeTrue();
        saleItem.ProductId.Should().BeNull();
        saleItem.ExternalProductName.Should().Be("Qo'shnidan olingan tovar");
        saleItem.ExternalCostPrice.Should().Be(5000m);
        saleItem.Quantity.Should().Be(3);
        saleItem.SalePrice.Should().Be(7000m);

        // Mahsulot stoki o'zgarmagan (tashqi mahsulot bazaga ta'sir qilmaydi)
        var productAfter = await DbContext.Products.FindAsync(product.Id);
        productAfter!.Quantity.Should().Be(initialStock);

        // Sale.TotalAmount = 3 * 7000 = 21000
        var saleAfter = await DbContext.Sales.FindAsync(sale.Id);
        saleAfter!.TotalAmount.Should().Be(21000m);

        // DTO IsExternal=true qaytaradi
        result.Should().NotBeNull();
        result!.IsExternal.Should().BeTrue();
    }

    [Fact]
    public async Task AddExternalItem_WithCostPriceGteSalePrice_ShouldThrow()
    {
        // Arrange
        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(TestCustomer.Id), TestUserId);

        // Tannarx (5000) sotuv narxiga (5000) teng — rad etilishi kerak
        var badRequest = new AddSaleItemDto(
            IsExternal: true,
            ProductId: null,
            ExternalProductName: "Yomon narx",
            ExternalCostPrice: 5000m,
            Quantity: 1,
            SalePrice: 5000m,
            MinSalePrice: 0m,
            Comment: null
        );

        // Act & Assert
        var act = async () => await SaleService.AddSaleItemAsync(sale!.Id, badRequest);
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*tannarx*");
    }

    [Fact]
    public async Task AddExternalItem_WithoutName_ShouldThrow()
    {
        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(TestCustomer.Id), TestUserId);

        var badRequest = new AddSaleItemDto(
            IsExternal: true,
            ProductId: null,
            ExternalProductName: null,
            ExternalCostPrice: 5000m,
            Quantity: 1,
            SalePrice: 7000m,
            MinSalePrice: 0m,
            Comment: null
        );

        var act = async () => await SaleService.AddSaleItemAsync(sale!.Id, badRequest);
        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*ExternalProductName*");
    }

    [Fact]
    public async Task AddSameExternalItemTwice_ShouldMergeQuantity()
    {
        // Arrange
        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(TestCustomer.Id), TestUserId);

        var request = new AddSaleItemDto(
            IsExternal: true,
            ProductId: null,
            ExternalProductName: "Coca-Cola 1L",
            ExternalCostPrice: 8000m,
            Quantity: 2,
            SalePrice: 12000m,
            MinSalePrice: 0m,
            Comment: null
        );

        // Act: bir xil nomli mahsulotni 2 marta qo'shamiz
        await SaleService.AddSaleItemAsync(sale!.Id, request);
        await SaleService.AddSaleItemAsync(sale.Id, request);

        // Assert: bitta SaleItem, quantity 4 ga teng (2 + 2)
        ClearDbContext();
        var items = await DbContext.SaleItems.Where(si => si.SaleId == sale.Id).ToListAsync();
        items.Should().HaveCount(1);
        items[0].Quantity.Should().Be(4);
        items[0].ExternalProductName.Should().Be("Coca-Cola 1L");

        // Sale.TotalAmount = 4 * 12000 = 48000
        var saleAfter = await DbContext.Sales.FindAsync(sale.Id);
        saleAfter!.TotalAmount.Should().Be(48000m);
    }

    [Fact]
    public async Task MixedSale_OrdinaryAndExternal_ShouldWorkCorrectly()
    {
        // Real-life scenario: bitta sotuvda ham oddiy, ham tashqi mahsulot
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var initialStock = product.Quantity;

        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(TestCustomer.Id), TestUserId);

        // Oddiy mahsulot qo'shamiz: 5 dona x 150 = 750
        await SaleService.AddSaleItemAsync(sale!.Id, new AddSaleItemDto(
            IsExternal: false,
            ProductId: product.Id,
            ExternalProductName: null,
            ExternalCostPrice: null,
            Quantity: 5,
            SalePrice: 150m,
            MinSalePrice: 100m,
            Comment: null
        ));

        // Tashqi mahsulot qo'shamiz: 2 dona x 7000 = 14000
        await SaleService.AddSaleItemAsync(sale.Id, new AddSaleItemDto(
            IsExternal: true,
            ProductId: null,
            ExternalProductName: "Qo'shnidan",
            ExternalCostPrice: 5000m,
            Quantity: 2,
            SalePrice: 7000m,
            MinSalePrice: 0m,
            Comment: null
        ));

        // Assert
        ClearDbContext();

        // Sotuvda 2 ta item
        var items = await DbContext.SaleItems.Where(si => si.SaleId == sale.Id).ToListAsync();
        items.Should().HaveCount(2);

        // Oddiy mahsulot stoki 5 ga kamaygan
        var productAfter = await DbContext.Products.FindAsync(product.Id);
        productAfter!.Quantity.Should().Be(initialStock - 5);

        // Sale.TotalAmount = 750 + 14000 = 14750
        var saleAfter = await DbContext.Sales.FindAsync(sale.Id);
        saleAfter!.TotalAmount.Should().Be(14750m);
    }
}
