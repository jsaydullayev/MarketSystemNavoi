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
/// Guards the Shift wiring on <see cref="ReportService.GetStaffPerformanceAsync"/>.
/// The placeholder `ShiftCount: 0 / IsActiveShift: false` lived in this method
/// long after the Shift entity landed — these tests make sure the dashboard's
/// staff leaderboard now reflects real shift sessions and current openness.
/// </summary>
public class ReportServiceStaffPerformanceTests : TestBase
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

    private void SeedShift(Guid userId, DateTime openedAt, DateTime? closedAt)
    {
        DbContext.Shifts.Add(new Shift
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            MarketId = TestMarketId,
            OpenedAt = openedAt,
            ClosedAt = closedAt,
        });
    }

    /// <summary>TestBase seeds TestUser with the enum default (SuperAdmin),
    /// which GetStaffPerformanceAsync filters out — bump the role to Seller
    /// so the user shows up on the leaderboard.</summary>
    private async Task PromoteTestUserToSellerAsync()
    {
        TestUser.Role = Role.Seller;
        await DbContext.SaveChangesAsync();
    }

    [Fact]
    public async Task GetStaffPerformance_CountsInPeriodShifts_AndFlagsActiveOnes()
    {
        await PromoteTestUserToSellerAsync();
        // TestUser already exists via the base seed. Two in-window closed
        // shifts → ShiftCount = 2. No open shift → IsActiveShift = false.
        var now = DateTime.UtcNow;
        SeedShift(TestUserId, now.AddHours(-5), now.AddHours(-3));
        SeedShift(TestUserId, now.AddHours(-2), now.AddHours(-1));
        await DbContext.SaveChangesAsync();

        var report = await CreateService().GetStaffPerformanceAsync("week");

        var row = report.Staff.Should().ContainSingle(r => r.UserId == TestUserId.ToString()).Subject;
        row.ShiftCount.Should().Be(2);
        row.IsActiveShift.Should().BeFalse();
    }

    [Fact]
    public async Task GetStaffPerformance_StillOpenShift_FlagsActive()
    {
        await PromoteTestUserToSellerAsync();
        var now = DateTime.UtcNow;
        // One closed shift today + one currently open. ShiftCount counts both
        // sessions opened in the period; IsActiveShift catches the open one.
        SeedShift(TestUserId, now.AddHours(-6), now.AddHours(-4));
        SeedShift(TestUserId, now.AddHours(-1), closedAt: null);
        await DbContext.SaveChangesAsync();

        var report = await CreateService().GetStaffPerformanceAsync("week");

        var row = report.Staff.Single(r => r.UserId == TestUserId.ToString());
        row.ShiftCount.Should().Be(2);
        row.IsActiveShift.Should().BeTrue();
    }

    [Fact]
    public async Task GetStaffPerformance_ShiftOpenedBeforePeriod_StillCountsAsActive()
    {
        await PromoteTestUserToSellerAsync();
        var now = DateTime.UtcNow;
        // Opened 30 days ago, never closed. With period="today", this falls
        // outside the count window — ShiftCount stays 0 — but the seller is
        // still on the clock, so IsActiveShift must be true.
        SeedShift(TestUserId, now.AddDays(-30), closedAt: null);
        await DbContext.SaveChangesAsync();

        var report = await CreateService().GetStaffPerformanceAsync("today");

        var row = report.Staff.Single(r => r.UserId == TestUserId.ToString());
        row.ShiftCount.Should().Be(0);
        row.IsActiveShift.Should().BeTrue();
    }

    [Fact]
    public async Task GetStaffPerformance_NoShifts_ReportsZeroAndInactive()
    {
        await PromoteTestUserToSellerAsync();
        // No SeedShift calls — TestUser has never opened a shift.
        var report = await CreateService().GetStaffPerformanceAsync("week");

        var row = report.Staff.Single(r => r.UserId == TestUserId.ToString());
        row.ShiftCount.Should().Be(0);
        row.IsActiveShift.Should().BeFalse();
    }

    // P2 — GetProfitSummaryAsync now does DB-side aggregation. The old code
    // loaded every Sale (including all-time) into memory just to sum profit.
    // These tests pin both the math AND the bucketing (today / week / month /
    // all) so a future refactor can't silently regress either dimension.

    private void SeedSaleWithProfit(decimal salePrice, decimal costPrice, decimal quantity, DateTime createdAt)
    {
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = TestUserId,
            Status = SaleStatus.Paid,
            TotalAmount = salePrice * quantity,
            PaidAmount = salePrice * quantity,
            MarketId = TestMarketId,
            CreatedAt = createdAt,
        };
        DbContext.Sales.Add(sale);

        DbContext.SaleItems.Add(new SaleItem
        {
            Id = Guid.NewGuid(),
            SaleId = sale.Id,
            ProductId = Guid.NewGuid(),
            IsExternal = false,
            Quantity = quantity,
            SalePrice = salePrice,
            CostPrice = costPrice,
        });
    }

    [Fact]
    public async Task GetProfitSummary_SumsAcrossAllBuckets()
    {
        // Buckets are aligned to Tashkent calendar day — but TestBase uses
        // TimeZoneInfo.Utc for the clock, so "today" is UTC midnight today.
        // Just use DateTime.UtcNow so every sale lands in today + week +
        // month + all.
        SeedSaleWithProfit(salePrice: 150m, costPrice: 100m, quantity: 2, createdAt: DateTime.UtcNow);
        // Profit per item: (150 - 100) * 2 = 100
        await DbContext.SaveChangesAsync();

        var summary = await CreateService().GetProfitSummaryAsync();

        summary.TodayProfit.Should().Be(100m);
        summary.WeekProfit.Should().Be(100m);
        summary.MonthProfit.Should().Be(100m);
        summary.TotalProfit.Should().Be(100m);
    }

    [Fact]
    public async Task GetProfitSummary_OnlyIncludesPaidOrDebtSales()
    {
        // Cancelled and Draft sales must NOT contribute profit even if they
        // have items. The DB-side filter mirrors the old in-memory check.
        // Seed two sales side-by-side with explicit Statuses so the test
        // isn't sensitive to ordering or timestamp granularity.
        var now = DateTime.UtcNow;
        SeedSaleWithProfit(150m, 100m, 1, now.AddSeconds(-2));
        SeedSaleWithProfit(200m, 100m, 1, now.AddSeconds(-1));
        await DbContext.SaveChangesAsync();

        var sales = await DbContext.Sales.OrderBy(s => s.CreatedAt).ToListAsync();
        sales[0].Status = SaleStatus.Cancelled;
        sales[1].Status = SaleStatus.Draft;
        await DbContext.SaveChangesAsync();

        var summary = await CreateService().GetProfitSummaryAsync();
        summary.TotalProfit.Should().Be(0m, "cancelled + draft sales must be excluded");
    }

    [Fact]
    public async Task GetProfitSummary_ExternalProductsUseExternalCost()
    {
        // External items have CostPrice = 0 (it's not used) and instead carry
        // ExternalCostPrice. The aggregation must pick the right column.
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = TestUserId,
            Status = SaleStatus.Paid,
            TotalAmount = 300m,
            PaidAmount = 300m,
            MarketId = TestMarketId,
            CreatedAt = DateTime.UtcNow,
        };
        DbContext.Sales.Add(sale);
        DbContext.SaleItems.Add(new SaleItem
        {
            Id = Guid.NewGuid(),
            SaleId = sale.Id,
            IsExternal = true,
            ProductId = null,
            ExternalProductName = "Sample external",
            ExternalCostPrice = 80m,   // ← used
            CostPrice = 0m,           // ← must NOT be used for IsExternal=true
            Quantity = 3,
            SalePrice = 100m,
        });
        await DbContext.SaveChangesAsync();

        var summary = await CreateService().GetProfitSummaryAsync();
        // Profit = (100 - 80) * 3 = 60. If the SUM accidentally used
        // CostPrice=0, it would have come out 300.
        summary.TotalProfit.Should().Be(60m);
    }
}
