using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
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
            clock);
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
}
