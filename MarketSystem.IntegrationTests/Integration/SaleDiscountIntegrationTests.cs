using FluentAssertions;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Sale-level chegirma (skidka) uchun integration testlar.
///
/// Asosiy shart: spiskadagi tovar narxi O'ZGARMAYDI, lekin to'lanadigan hisob
/// (Sale.TotalAmount) chegirma hisobiga kamayadi — va keyingi to'lov/qarz
/// hisob-kitobi aynan shu kamaytirilgan summaga nisbatan ishlaydi.
/// </summary>
public class SaleDiscountIntegrationTests : TestBase
{
    /// 7 × 150 000 = 1 050 000 spiska; 50 000 chegirma → hisob 1 000 000.
    private const decimal UnitSalePrice = 150_000m;
    private const decimal UnitCostPrice = 100_000m;
    private const decimal Qty = 7m;
    private const decimal Gross = 1_050_000m;   // 7 × 150 000
    private const decimal Discount = 50_000m;
    private const decimal Net = 1_000_000m;     // Gross − Discount

    private async Task<Guid> CreateSaleWithItemsAsync()
    {
        var product = CreateTestProduct(costPrice: UnitCostPrice, salePrice: UnitSalePrice);
        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(TestCustomer.Id), TestUserId);

        await SaleService.AddSaleItemAsync(sale!.Id, new AddSaleItemDto(
            IsExternal: false,
            ProductId: product.Id,
            ExternalProductName: null,
            ExternalCostPrice: null,
            Quantity: Qty,
            SalePrice: UnitSalePrice,
            MinSalePrice: 0m,
            Comment: null));

        return sale.Id;
    }

    [Fact]
    public async Task SetDiscount_ShouldReduceChargedTotal_ButLeaveItemPricesIntact()
    {
        var saleId = await CreateSaleWithItemsAsync();

        // Chegirmadan oldin: hisob = spiska summasi
        ClearDbContext();
        (await DbContext.Sales.FindAsync(saleId))!.TotalAmount.Should().Be(Gross);

        // Act
        var dto = await SaleService.SetSaleDiscountAsync(saleId, Discount);

        // Assert
        ClearDbContext();
        var sale = await DbContext.Sales.FindAsync(saleId);
        sale!.DiscountAmount.Should().Be(Discount);
        sale.TotalAmount.Should().Be(Net, "hisob = spiska summasi − chegirma");

        // Spiskadagi tovar narxi O'ZGARMAGAN — chegirma faqat jamiga qo'llanadi
        var item = await DbContext.SaleItems.FirstAsync(si => si.SaleId == saleId);
        item.SalePrice.Should().Be(UnitSalePrice);
        item.Quantity.Should().Be(Qty);
        (item.SalePrice * item.Quantity).Should().Be(Gross);

        // DTO ham chegirmani va net hisobni qaytaradi (klient/hisobot uchun)
        dto!.DiscountAmount.Should().Be(Discount);
        dto.TotalAmount.Should().Be(Net);
    }

    [Fact]
    public async Task PayingDiscountedTotal_ShouldFullyCloseSale_WithNoDebt()
    {
        var saleId = await CreateSaleWithItemsAsync();
        await SaleService.SetSaleDiscountAsync(saleId, Discount);

        // Act: mijoz aynan chegirilgan hisobni to'laydi (spiska summasini emas)
        await SaleService.AddPaymentAsync(saleId, new AddPaymentDto("Cash", Net));

        // Assert: savdo to'liq to'langan — chegirma qarz bo'lib qolmaydi
        ClearDbContext();
        var sale = await DbContext.Sales.FindAsync(saleId);
        sale!.Status.Should().Be(SaleStatus.Paid);
        sale.PaidAmount.Should().Be(Net);
        (sale.TotalAmount - sale.PaidAmount).Should().Be(0m, "chegirma fantom qarz qoldirmasligi kerak");

        var debt = await DbContext.Debts.FirstOrDefaultAsync(d => d.SaleId == saleId);
        debt.Should().BeNull();
    }

    [Fact]
    public async Task PaymentAboveDiscountedTotal_ShouldBeRejected()
    {
        var saleId = await CreateSaleWithItemsAsync();
        await SaleService.SetSaleDiscountAsync(saleId, Discount);

        // Chegirmadan keyin spiska summasini to'lash — ortiqcha to'lov
        var act = async () => await SaleService.AddPaymentAsync(saleId, new AddPaymentDto("Cash", Gross));

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task PartialPaymentAfterDiscount_ShouldCreateDebtFromDiscountedTotal()
    {
        var saleId = await CreateSaleWithItemsAsync();
        await SaleService.SetSaleDiscountAsync(saleId, Discount);

        // Net 1 000 000 dan 600 000 to'lanadi → qarz 400 000 (1 050 000 dan emas)
        await SaleService.AddPaymentAsync(saleId, new AddPaymentDto("Cash", 600_000m));

        ClearDbContext();
        var sale = await DbContext.Sales.FindAsync(saleId);
        sale!.Status.Should().Be(SaleStatus.Debt);

        var debt = await DbContext.Debts.FirstAsync(d => d.SaleId == saleId);
        debt.TotalDebt.Should().Be(Net);
        debt.RemainingDebt.Should().Be(400_000m, "qarz chegirilgan hisobdan hisoblanadi");
    }

    [Fact]
    public async Task SetDiscount_ExceedingItemTotal_ShouldThrow()
    {
        var saleId = await CreateSaleWithItemsAsync();

        var act = async () => await SaleService.SetSaleDiscountAsync(saleId, Gross + 1m);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*oshib ketmasligi*");
    }

    [Fact]
    public async Task SetNegativeDiscount_ShouldThrow()
    {
        var saleId = await CreateSaleWithItemsAsync();

        var act = async () => await SaleService.SetSaleDiscountAsync(saleId, -1m);

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task SetDiscount_OnPaidSale_ShouldThrow()
    {
        var saleId = await CreateSaleWithItemsAsync();
        await SaleService.AddPaymentAsync(saleId, new AddPaymentDto("Cash", Gross));

        // Yakunlangan savdo summasi muzlatilgan — chegirma qo'llab bo'lmaydi
        var act = async () => await SaleService.SetSaleDiscountAsync(saleId, Discount);

        await act.Should().ThrowAsync<InvalidOperationException>();
    }
}
