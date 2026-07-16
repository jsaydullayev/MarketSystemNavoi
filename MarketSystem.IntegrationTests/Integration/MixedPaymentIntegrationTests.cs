using FluentAssertions;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Aralash (multi-tender) to'lov uchun integration testlar.
///
/// Regression: a walk-in (mijozsiz) sale paid part cash + part card used to
/// fail. The client posted each split to the single-payment endpoint, and the
/// backend evaluated the no-customer-debt guard on the FIRST partial split —
/// throwing "Mijoz tanlanmagan..." even though the two splits together covered
/// the bill. AddPaymentsAsync applies every split atomically and validates the
/// SUM, so the walk-in mixed payment now succeeds.
/// </summary>
public class MixedPaymentIntegrationTests : TestBase
{
    private const decimal UnitPrice = 50_000m;
    private const decimal Qty = 2m;
    private const decimal Total = 100_000m; // 2 × 50 000

    private async Task<Guid> CreateSaleWithItemsAsync(Guid? customerId)
    {
        var product = CreateTestProduct(costPrice: 30_000m, salePrice: UnitPrice);
        var sale = await SaleService.CreateSaleAsync(new CreateSaleDto(customerId), TestUserId);
        await SaleService.AddSaleItemAsync(sale!.Id, new AddSaleItemDto(
            IsExternal: false,
            ProductId: product.Id,
            ExternalProductName: null,
            ExternalCostPrice: null,
            Quantity: Qty,
            SalePrice: UnitPrice,
            MinSalePrice: 0m,
            Comment: null));
        return sale.Id;
    }

    [Fact]
    public async Task AddPayments_MixedTender_NoCustomer_FullyPaid_Succeeds()
    {
        // The exact failing scenario: walk-in, no customer, Cash + Card = full.
        var saleId = await CreateSaleWithItemsAsync(customerId: null);

        var result = await SaleService.AddPaymentsAsync(saleId, new[]
        {
            new AddPaymentDto("Cash", 50_000m),
            new AddPaymentDto("Card", 50_000m), // maps to Terminal
        });

        result.Should().NotBeNull();
        ClearDbContext();

        var sale = await DbContext.Sales.FindAsync(saleId);
        sale!.Status.Should().Be(SaleStatus.Paid, "sum of tenders covers the whole bill");
        sale.PaidAmount.Should().Be(Total);

        var payments = await DbContext.Payments.Where(p => p.SaleId == saleId).ToListAsync();
        payments.Should().HaveCount(2);
        payments.Sum(p => p.Amount).Should().Be(Total);
        payments.Should().Contain(p => p.PaymentType == PaymentType.Cash && p.Amount == 50_000m);
        payments.Should().Contain(p => p.PaymentType == PaymentType.Terminal && p.Amount == 50_000m,
            "the frontend 'Card' label maps to Terminal");

        // No debt row for a fully-paid sale.
        (await DbContext.Debts.AnyAsync(d => d.SaleId == saleId)).Should().BeFalse();
    }

    [Fact]
    public async Task AddPayments_MixedTender_OnlyCashPortionHitsCashRegister()
    {
        var saleId = await CreateSaleWithItemsAsync(customerId: null);

        await SaleService.AddPaymentsAsync(saleId, new[]
        {
            new AddPaymentDto("Cash", 30_000m),
            new AddPaymentDto("Card", 70_000m),
        });

        ClearDbContext();
        var register = await DbContext.CashRegisters.FirstAsync(cr => cr.MarketId == TestMarketId);
        register.CurrentBalance.Should().Be(30_000m,
            "only the cash split moves physical till money; Card/Terminal does not");
    }

    [Fact]
    public async Task AddPayments_SumLeavesBalance_NoCustomer_Throws()
    {
        // Sum of tenders < total AND no customer → still a no-customer debt, still rejected.
        var saleId = await CreateSaleWithItemsAsync(customerId: null);

        var act = async () => await SaleService.AddPaymentsAsync(saleId, new[]
        {
            new AddPaymentDto("Cash", 30_000m),
            new AddPaymentDto("Card", 20_000m), // 50k of 100k → 50k debt, no customer
        });

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*Mijoz tanlanmagan*");
    }

    [Fact]
    public async Task AddPayments_PartialSum_WithCustomer_CreatesDebt()
    {
        var saleId = await CreateSaleWithItemsAsync(customerId: TestCustomer.Id);

        await SaleService.AddPaymentsAsync(saleId, new[]
        {
            new AddPaymentDto("Cash", 40_000m),
            new AddPaymentDto("Card", 20_000m), // 60k of 100k
        });

        ClearDbContext();
        var sale = await DbContext.Sales.FindAsync(saleId);
        sale!.Status.Should().Be(SaleStatus.Debt);
        sale.PaidAmount.Should().Be(60_000m);

        var debt = await DbContext.Debts.FirstOrDefaultAsync(d => d.SaleId == saleId);
        debt.Should().NotBeNull("a partial payment with a customer records a debt");
        debt!.RemainingDebt.Should().Be(40_000m);
    }

    [Fact]
    public async Task AddPayments_OverTotal_Throws()
    {
        var saleId = await CreateSaleWithItemsAsync(customerId: null);

        var act = async () => await SaleService.AddPaymentsAsync(saleId, new[]
        {
            new AddPaymentDto("Cash", 60_000m),
            new AddPaymentDto("Card", 60_000m), // 120k > 100k
        });

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*qoldiq summadan oshib ketdi*");
    }

    [Fact]
    public async Task AddPayment_Single_PartialNoCustomer_StillThrows()
    {
        // Teeth / documentation: the single-tender path (used for debt
        // installments) still rejects a genuine no-customer partial payment.
        // This is exactly why multi-tender needs its own atomic, sum-validating
        // path rather than looping this endpoint.
        var saleId = await CreateSaleWithItemsAsync(customerId: null);

        var act = async () => await SaleService.AddPaymentAsync(saleId, new AddPaymentDto("Cash", 50_000m));

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*Mijoz tanlanmagan*");
    }
}
