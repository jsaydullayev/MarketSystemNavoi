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
/// DebtService had no direct tests — Y6 fix made PayAsync runnable on the
/// InMemory provider (was raw SQL FOR UPDATE only), so we can finally lock
/// in the contract:
///   • Pay reduces RemainingDebt by the amount and writes a Payment row
///   • Pay closes the Debt when RemainingDebt reaches zero
///   • Pay refuses overpayment, already-closed debts, and zero/negative amounts
///   • Pay writes an audit row
///   • Cash payments update the till; non-cash payments do not
///   • Cross-tenant debt Ids are 404-equivalent (KeyNotFoundException)
/// </summary>
public class DebtServiceTests : TestBase
{
    private DebtService CreateService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new DebtService(
            DbContext,
            unitOfWork,
            CurrentMarketServiceMock.Object,
            AuditLogServiceMock.Object,
            NullLogger<DebtService>.Instance);
    }

    /// <summary>Set up a Customer + dummy Sale + open Debt directly.</summary>
    private async Task<Debt> SeedDebtAsync(decimal totalDebt = 300m, decimal alreadyPaid = 0m, int? marketId = null)
    {
        var mId = marketId ?? TestMarketId;
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = TestUserId,
            CustomerId = TestCustomer.Id,
            TotalAmount = totalDebt,
            PaidAmount = alreadyPaid,
            Status = SaleStatus.Debt,
            MarketId = mId,
            CreatedAt = DateTime.UtcNow,
        };
        DbContext.Sales.Add(sale);

        var debt = new Debt
        {
            Id = Guid.NewGuid(),
            SaleId = sale.Id,
            CustomerId = TestCustomer.Id,
            TotalDebt = totalDebt,
            RemainingDebt = totalDebt - alreadyPaid,
            Status = DebtStatus.Open,
            MarketId = mId,
            CreatedAt = DateTime.UtcNow,
        };
        DbContext.Debts.Add(debt);
        await DbContext.SaveChangesAsync();
        return debt;
    }

    // ───────────────────── PayAsync — happy paths ─────────────────────

    [Fact]
    public async Task PayAsync_PartialCash_DecrementsRemaining_AndUpdatesTill()
    {
        var debt = await SeedDebtAsync(totalDebt: 300m);
        var register = await DbContext.CashRegisters.FirstAsync(r => r.MarketId == TestMarketId);
        var initialBalance = register.CurrentBalance;

        var result = await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(100m, "Cash"),
            TestUserId);

        result.Should().NotBeNull();
        result.PaymentAmount.Should().Be(100m);
        result.RemainingDebt.Should().Be(200m);

        ClearDbContext();
        var updated = await DbContext.Debts.FirstAsync(d => d.Id == debt.Id);
        updated.RemainingDebt.Should().Be(200m);
        updated.Status.Should().Be(DebtStatus.Open);

        var tillAfter = await DbContext.CashRegisters.FirstAsync(r => r.MarketId == TestMarketId);
        tillAfter.CurrentBalance.Should().Be(initialBalance + 100m,
            "cash debt payments are revenue and must hit the till");
    }

    [Fact]
    public async Task PayAsync_FullCash_ClosesDebt()
    {
        var debt = await SeedDebtAsync(totalDebt: 100m);

        var result = await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(100m, "Cash"),
            TestUserId);

        result.RemainingDebt.Should().Be(0m);

        ClearDbContext();
        var updated = await DbContext.Debts.FirstAsync(d => d.Id == debt.Id);
        updated.RemainingDebt.Should().Be(0m);
        updated.Status.Should().Be(DebtStatus.Closed);
    }

    [Fact]
    public async Task PayAsync_CardPayment_DoesNotTouchTill()
    {
        var debt = await SeedDebtAsync(totalDebt: 500m);
        var register = await DbContext.CashRegisters.FirstAsync(r => r.MarketId == TestMarketId);
        var initialBalance = register.CurrentBalance;

        await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(200m, "Terminal"),
            TestUserId);

        ClearDbContext();
        var tillAfter = await DbContext.CashRegisters.FirstAsync(r => r.MarketId == TestMarketId);
        tillAfter.CurrentBalance.Should().Be(initialBalance,
            "Terminal/Card/Click payments go through external rails — the till stays put");
    }

    [Fact]
    public async Task PayAsync_RecordsPaymentRowOnSale()
    {
        var debt = await SeedDebtAsync(totalDebt: 200m);

        await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(50m, "Cash"),
            TestUserId);

        ClearDbContext();
        var payments = await DbContext.Payments.Where(p => p.SaleId == debt.SaleId).ToListAsync();
        payments.Should().ContainSingle();
        payments[0].Amount.Should().Be(50m);
        payments[0].PaymentType.Should().Be(PaymentType.Cash);
    }

    [Fact]
    public async Task PayAsync_WritesAuditRow()
    {
        var debt = await SeedDebtAsync(totalDebt: 100m);

        await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(50m, "Cash"),
            TestUserId);

        AuditLogServiceMock.Verify(x => x.LogPaymentActionAsync(
            It.IsAny<Guid>(), TestUserId, It.IsAny<CancellationToken>()), Times.Once);
    }

    // ───────────────────── PayAsync — rejection paths ─────────────────────

    [Fact]
    public async Task PayAsync_Overpayment_Throws()
    {
        var debt = await SeedDebtAsync(totalDebt: 100m);

        Func<Task> act = async () => await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(150m, "Cash"),
            TestUserId);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*qoldiq qarzdan*");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-10)]
    public async Task PayAsync_ZeroOrNegativeAmount_Throws(decimal amount)
    {
        var debt = await SeedDebtAsync();

        Func<Task> act = async () => await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(amount, "Cash"),
            TestUserId);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*0 dan katta*");
    }

    [Fact]
    public async Task PayAsync_ClosedDebt_Throws()
    {
        var debt = await SeedDebtAsync(totalDebt: 100m);
        debt.Status = DebtStatus.Closed;
        await DbContext.SaveChangesAsync();

        Func<Task> act = async () => await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(10m, "Cash"),
            TestUserId);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*yopilgan*");
    }

    [Fact]
    public async Task PayAsync_UnknownDebt_Throws()
    {
        Func<Task> act = async () => await CreateService().PayAsync(
            Guid.NewGuid(),
            new PayDebtDto(10m, "Cash"),
            TestUserId);

        await act.Should().ThrowAsync<KeyNotFoundException>();
    }

    [Fact]
    public async Task PayAsync_OtherMarketDebt_Throws()
    {
        // Defensive multi-tenant isolation — a caller in market A must not
        // be able to settle a debt belonging to market B by passing its Guid.
        var otherMarketId = 9200;
        DbContext.Markets.Add(new Market { Id = otherMarketId, Name = "Other", Subdomain = "d-other", OwnerId = Guid.NewGuid() });
        await DbContext.SaveChangesAsync();
        var foreign = await SeedDebtAsync(totalDebt: 100m, marketId: otherMarketId);

        Func<Task> act = async () => await CreateService().PayAsync(
            foreign.Id,
            new PayDebtDto(50m, "Cash"),
            TestUserId);

        await act.Should().ThrowAsync<KeyNotFoundException>();
    }

    [Fact]
    public async Task PayAsync_InvalidPaymentType_Throws()
    {
        var debt = await SeedDebtAsync();

        Func<Task> act = async () => await CreateService().PayAsync(
            debt.Id,
            new PayDebtDto(50m, "Bitcoin"),
            TestUserId);

        await act.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*Noto'g'ri to'lov turi*");
    }

    // ───────────────────── List queries ─────────────────────

    [Fact]
    public async Task GetByCustomer_ReturnsOnlyOpenDebtsInOwnMarket()
    {
        await SeedDebtAsync(totalDebt: 100m); // Open
        var closed = await SeedDebtAsync(totalDebt: 50m);
        closed.Status = DebtStatus.Closed;
        await DbContext.SaveChangesAsync();

        var debts = (await CreateService().GetByCustomerAsync(TestCustomer.Id)).ToList();
        debts.Should().HaveCount(1, "only Open debts should appear");
    }

    [Fact]
    public async Task GetCustomerTotal_SumsRemainingDebtAcrossOpenDebts()
    {
        await SeedDebtAsync(totalDebt: 100m, alreadyPaid: 20m);  // remaining 80
        await SeedDebtAsync(totalDebt: 50m);                      // remaining 50

        var total = await CreateService().GetCustomerTotalAsync(TestCustomer.Id);
        total.Should().Be(130m);
    }
}
