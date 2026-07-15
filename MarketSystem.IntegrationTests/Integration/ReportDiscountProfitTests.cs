using FluentAssertions;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Chegirma (skidka) HISOBOTLARGA to'g'ri ta'sir qilishini qotiradi.
///
/// Foyda har doim GROSS item tushumidan hisoblanadi ((SalePrice-cost)*Qty), shuning
/// uchun har bir sale bo'yicha DiscountAmount BIR MARTA ayrilishi shart. Bu — qo'lda
/// tugatilgan, nozik joy (ayniqsa GetProfitSummaryAsync'dagi DB-yig'ma), shuning uchun
/// regressiyadan himoya kerak: kelajakdagi tahrir ikki marta ayirmasin yoki
/// ayirishni tushirib qoldirmasin.
/// </summary>
public class ReportDiscountProfitTests : TestBase
{
    private ReportService CreateService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        var clock = new TashkentClock(TimeZoneInfo.Utc);
        return new ReportService(
            unitOfWork,
            CurrentMarketServiceMock.Object,
            NullLogger<ReportService>.Instance,
            clock,
            DbContext);
    }

    /// 10 dona × 150 000 sotildi, tannarx 100 000 → gross foyda 500 000.
    /// 50 000 chegirma → net foyda 450 000, net tushum 1 450 000.
    private const decimal Qty = 10m;
    private const decimal SalePrice = 150_000m;
    private const decimal CostPrice = 100_000m;
    private const decimal Gross = 1_500_000m;   // Qty * SalePrice
    private const decimal GrossProfit = 500_000m; // (SalePrice-Cost)*Qty
    private const decimal Discount = 50_000m;

    /// Bugungi kun (Tashkent=UTC test'da), yakunlangan, chegirmali sotuv.
    private async Task SeedDiscountedSaleTodayAsync(decimal discount)
    {
        var saleId = Guid.NewGuid();
        DbContext.Sales.Add(new Sale
        {
            Id = saleId,
            SellerId = TestUserId,
            MarketId = TestMarketId,
            Status = SaleStatus.Paid,
            DiscountAmount = discount,
            TotalAmount = Gross - discount,
            PaidAmount = Gross - discount,
            CreatedAt = DateTime.UtcNow,
        });
        DbContext.SaleItems.Add(new SaleItem
        {
            Id = Guid.NewGuid(),
            SaleId = saleId,
            IsExternal = false,
            Quantity = Qty,
            SalePrice = SalePrice,
            CostPrice = CostPrice,
            CreatedAt = DateTime.UtcNow,
        });
        await DbContext.SaveChangesAsync();
        ClearDbContext();
    }

    [Fact]
    public async Task ProfitSummary_SubtractsDiscount_Once()
    {
        await SeedDiscountedSaleTodayAsync(Discount);

        var summary = await CreateService().GetProfitSummaryAsync();

        // Net foyda = gross foyda − chegirma (BIR marta).
        summary.TodayProfit.Should().Be(GrossProfit - Discount);
        summary.WeekProfit.Should().Be(GrossProfit - Discount);
        summary.MonthProfit.Should().Be(GrossProfit - Discount);
        summary.TotalProfit.Should().Be(GrossProfit - Discount);
    }

    [Fact]
    public async Task ProfitSummary_WithoutDiscount_EqualsGrossProfit()
    {
        // Nazorat: chegirma 0 bo'lsa, hech narsa ayrilmaydi (ikki marta ayirish
        // yoki noto'g'ri manfiy siljish bo'lmasligini isbotlaydi).
        await SeedDiscountedSaleTodayAsync(0m);

        var summary = await CreateService().GetProfitSummaryAsync();

        summary.TodayProfit.Should().Be(GrossProfit);
        summary.TotalProfit.Should().Be(GrossProfit);
    }

    [Fact]
    public async Task DailyReport_ProfitReflectsDiscount()
    {
        // CalculateReport yo'li (dashboard/kunlik hisobot) ham chegirmani ayiradi.
        await SeedDiscountedSaleTodayAsync(Discount);

        var report = await CreateService().GetDailyReportAsync(
            DateTime.UtcNow, userRole: Role.Owner.ToString());

        report.Profit.Should().Be(GrossProfit - Discount);
        // Tushum (TotalAmount asosida) allaqachon net — qo'sh ayirish bo'lmasligi kerak.
        report.TotalSales.Should().Be(Gross - Discount);
    }
}
