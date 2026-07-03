using System.Net;
using System.Text.Json;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Verifies the real <see cref="AuditLogService"/> — the audit-write path that
/// every other test stubs with a mock. Covers row creation, payload
/// serialisation and the client-IP capture added in Plan 07, Bosqich 1.
/// </summary>
public class AuditLogIntegrationTests : TestBase
{
    private AuditLogService CreateService(IHttpContextAccessor httpContextAccessor)
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        // TryGetCurrentMarketId backs AuditLog.MarketId — TestBase only wires
        // GetCurrentMarketId, so it is set up explicitly here.
        CurrentMarketServiceMock.Setup(x => x.TryGetCurrentMarketId()).Returns(TestMarketId);
        return new AuditLogService(
            unitOfWork,
            NullLogger<AuditLogService>.Instance,
            CurrentMarketServiceMock.Object,
            httpContextAccessor,
            DbContext);
    }

    private static IHttpContextAccessor HttpContextWith(string? remoteIp)
    {
        var accessor = new Mock<IHttpContextAccessor>();
        if (remoteIp is null)
        {
            accessor.Setup(x => x.HttpContext).Returns((HttpContext?)null);
        }
        else
        {
            var ctx = new DefaultHttpContext();
            ctx.Connection.RemoteIpAddress = IPAddress.Parse(remoteIp);
            accessor.Setup(x => x.HttpContext).Returns(ctx);
        }
        return accessor.Object;
    }

    [Fact]
    public async Task LogAction_WritesRowWithCoreFields()
    {
        var service = CreateService(HttpContextWith(remoteIp: null));
        var entityId = Guid.NewGuid();

        await service.LogActionAsync("Sale", entityId, "Create", TestUserId,
            new { foo = "bar" });

        var log = await DbContext.Set<AuditLog>().SingleAsync();
        log.EntityType.Should().Be("Sale");
        log.EntityId.Should().Be(entityId);
        log.Action.Should().Be("Create");
        log.UserId.Should().Be(TestUserId);
        log.MarketId.Should().Be(TestMarketId);
        log.Payload.Should().Contain("bar");
        log.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
    }

    [Fact]
    public async Task LogAction_CapturesClientIpFromHttpContext()
    {
        var service = CreateService(HttpContextWith("203.0.113.7"));

        await service.LogActionAsync("Auth", Guid.Empty, "LoginFailed", Guid.Empty);

        var log = await DbContext.Set<AuditLog>().SingleAsync();
        log.IpAddress.Should().Be("203.0.113.7");
    }

    [Fact]
    public async Task LogAction_WithNoHttpContext_LeavesIpAddressNull()
    {
        var service = CreateService(HttpContextWith(remoteIp: null));

        await service.LogActionAsync("Auth", Guid.Empty, "Login", TestUserId);

        var log = await DbContext.Set<AuditLog>().SingleAsync();
        log.IpAddress.Should().BeNull();
    }

    [Fact]
    public async Task LogAction_WithNullPayload_StoresEmptyString()
    {
        var service = CreateService(HttpContextWith(remoteIp: null));

        await service.LogActionAsync("Auth", TestUserId, "Logout", TestUserId);

        var log = await DbContext.Set<AuditLog>().SingleAsync();
        log.Payload.Should().BeEmpty();
    }

    [Fact]
    public async Task LogAction_WithEmptyUserId_StoresNullUserId()
    {
        // Mirrors what AuthService does on a failed login — the username
        // didn't resolve to a real account, so the caller passes Guid.Empty.
        // The service must store NULL or the FK to Users will reject the row
        // in production (in-memory tests don't enforce FKs).
        var service = CreateService(HttpContextWith(remoteIp: null));

        await service.LogActionAsync("Auth", Guid.Empty, "LoginFailed", Guid.Empty);

        var log = await DbContext.Set<AuditLog>().SingleAsync();
        log.UserId.Should().BeNull();
    }

    // ─── Read API (Plan 07 Bosqich 2) ─────────────────────────────────────

    /// <summary>Direct-insert an audit row so the read tests have
    /// deterministic timestamps / market IDs (the write API uses
    /// DateTime.UtcNow which is too coarse for ordering assertions).</summary>
    private AuditLog SeedRow(
        string entityType = "Sale",
        string action = "Create",
        Guid? userId = null,
        int? marketId = null,
        DateTime? createdAt = null)
    {
        var row = new AuditLog
        {
            Id = Guid.NewGuid(),
            EntityType = entityType,
            EntityId = Guid.NewGuid(),
            Action = action,
            UserId = userId ?? TestUserId,
            MarketId = marketId ?? TestMarketId,
            Payload = string.Empty,
            CreatedAt = createdAt ?? DateTime.UtcNow,
        };
        DbContext.AuditLogs.Add(row);
        return row;
    }

    private IAuditLogQueryService QueryService()
        => CreateService(HttpContextWith(remoteIp: null));

    [Fact]
    public async Task Query_ReturnsRowsOrderedByCreatedAtDescending()
    {
        SeedRow(action: "Create", createdAt: new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc));
        SeedRow(action: "Cancel", createdAt: new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc));
        SeedRow(action: "Update", createdAt: new DateTime(2026, 3, 1, 0, 0, 0, DateTimeKind.Utc));
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(new AuditLogFilter(), allowCrossMarket: true);

        result.Total.Should().Be(3);
        result.Items.Select(i => i.Action).Should().Equal("Cancel", "Update", "Create");
    }

    [Fact]
    public async Task Query_FilterByEntityType_NarrowsResults()
    {
        SeedRow(entityType: "Sale");
        SeedRow(entityType: "Sale");
        SeedRow(entityType: "Payment");
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(new AuditLogFilter(EntityType: "Sale"), allowCrossMarket: true);

        result.Total.Should().Be(2);
        result.Items.Should().OnlyContain(i => i.EntityType == "Sale");
    }

    [Fact]
    public async Task Query_FilterByActionAndUserId_NarrowsResults()
    {
        var otherUser = Guid.NewGuid();
        SeedRow(action: "Login", userId: TestUserId);
        SeedRow(action: "Login", userId: otherUser);
        SeedRow(action: "LoginFailed", userId: TestUserId);
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(
            new AuditLogFilter(Action: "Login", UserId: TestUserId), allowCrossMarket: true);

        result.Total.Should().Be(1);
        result.Items[0].Action.Should().Be("Login");
        result.Items[0].UserId.Should().Be(TestUserId);
    }

    [Fact]
    public async Task Query_FilterByMarketIdAndDateRange_NarrowsResults()
    {
        var inRange = new DateTime(2026, 5, 15, 12, 0, 0, DateTimeKind.Utc);
        var beforeRange = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        var otherMarket = TestMarketId + 1000;

        SeedRow(marketId: TestMarketId, createdAt: inRange);
        SeedRow(marketId: TestMarketId, createdAt: beforeRange);
        SeedRow(marketId: otherMarket, createdAt: inRange); // wrong market — filtered out
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(new AuditLogFilter(
            MarketId: TestMarketId,
            FromUtc: new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc),
            ToUtc: new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc)));

        result.Total.Should().Be(1);
        result.Items[0].MarketId.Should().Be(TestMarketId);
        result.Items[0].CreatedAt.Should().Be(inRange);
    }

    [Fact]
    public async Task Query_PopulatesUserNameFromJoin()
    {
        SeedRow(userId: TestUserId); // TestUser.FullName = "Test User"
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(new AuditLogFilter(), allowCrossMarket: true);

        result.Items[0].UserName.Should().Be("Test User");
    }

    [Fact]
    public async Task Query_AnonymousRow_HasNullUserName()
    {
        // Direct-insert with null UserId — what LoginFailed writes via the
        // Guid.Empty → null mapping. The LEFT JOIN to Users must keep UserName null.
        DbContext.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            EntityType = "Auth",
            EntityId = Guid.Empty,
            Action = "LoginFailed",
            UserId = null,
            MarketId = TestMarketId,
            Payload = string.Empty,
            CreatedAt = DateTime.UtcNow,
        });
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(new AuditLogFilter(), allowCrossMarket: true);

        result.Total.Should().Be(1);
        result.Items[0].UserId.Should().BeNull();
        result.Items[0].UserName.Should().BeNull();
    }

    [Fact]
    public async Task Query_PagingReturnsCorrectSliceAndTotalCount()
    {
        // 5 rows, page size 2 → page 2 should contain rows #3 and #4 (newest-first).
        for (var i = 0; i < 5; i++)
            SeedRow(action: $"A{i}", createdAt: new DateTime(2026, 1, 1).AddMinutes(i));
        await DbContext.SaveChangesAsync();

        var result = await QueryService().QueryAsync(new AuditLogFilter(Page: 2, Size: 2), allowCrossMarket: true);

        result.Total.Should().Be(5);
        result.Page.Should().Be(2);
        result.Size.Should().Be(2);
        result.TotalPages.Should().Be(3);
        result.Items.Should().HaveCount(2);
        // Newest-first ordering — page 2 skips A4+A3 (page 1), returns A2+A1.
        result.Items.Select(i => i.Action).Should().Equal("A2", "A1");
    }

    [Fact]
    public async Task Query_PageAndSizeBoundsAreClamped()
    {
        SeedRow();
        await DbContext.SaveChangesAsync();

        // size below 1 clamps up to 1; size above 200 clamps down to 200; page
        // below 1 clamps up to 1. The clamp values surface on the response so
        // the client can render correct paging controls.
        var below = await QueryService().QueryAsync(new AuditLogFilter(Page: 0, Size: 0), allowCrossMarket: true);
        below.Page.Should().Be(1);
        below.Size.Should().Be(1);

        var above = await QueryService().QueryAsync(new AuditLogFilter(Size: 5000), allowCrossMarket: true);
        above.Size.Should().Be(200);
    }

    // ─── Suspicious-activity detection (Plan 07 Bosqich 3) ────────────────

    /// <summary>Insert a LoginFailed row with a username payload — the shape
    /// AuthService writes in production. UserId stays null (anonymous).</summary>
    private void SeedLoginFailed(string username, string? ipAddress, DateTime createdAt, int? marketId = null)
    {
        DbContext.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            EntityType = AuditEntityTypes.Auth,
            EntityId = Guid.Empty,
            Action = AuditActions.LoginFailed,
            UserId = null,
            MarketId = marketId ?? TestMarketId,
            Payload = JsonSerializer.Serialize(new { username }),
            IpAddress = ipAddress,
            CreatedAt = createdAt,
        });
    }

    [Fact]
    public async Task GetSuspicious_NoActivity_ReturnsEmptyReport()
    {
        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.FailedLoginBursts.Should().BeEmpty();
        report.BulkDeleteBursts.Should().BeEmpty();
    }

    [Fact]
    public async Task GetSuspicious_FailedLoginBurst_FlagsAtThreshold()
    {
        var now = DateTime.UtcNow;
        for (var i = 0; i < 5; i++)
            SeedLoginFailed("bob", ipAddress: "1.2.3.4", createdAt: now.AddMinutes(-i));
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.FailedLoginBursts.Should().HaveCount(1);
        var burst = report.FailedLoginBursts[0];
        burst.Username.Should().Be("bob");
        burst.Count.Should().Be(5);
        burst.IpAddresses.Should().Equal("1.2.3.4");
    }

    [Fact]
    public async Task GetSuspicious_FailedLoginBurst_BelowThreshold_NotFlagged()
    {
        var now = DateTime.UtcNow;
        for (var i = 0; i < 4; i++) // 4 < threshold of 5
            SeedLoginFailed("alice", ipAddress: "1.2.3.4", createdAt: now.AddMinutes(-i));
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.FailedLoginBursts.Should().BeEmpty();
    }

    [Fact]
    public async Task GetSuspicious_FailedLoginBurst_IgnoresEventsOutsideWindow()
    {
        var now = DateTime.UtcNow;
        // 5 events INSIDE the 15-min window — should flag with count == 5.
        for (var i = 0; i < 5; i++)
            SeedLoginFailed("carol", ipAddress: "1.2.3.4", createdAt: now.AddMinutes(-i));
        // One extra OUTSIDE the window — must be ignored, count must stay 5.
        SeedLoginFailed("carol", ipAddress: "1.2.3.4", createdAt: now.AddMinutes(-30));
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.FailedLoginBursts.Should().HaveCount(1);
        report.FailedLoginBursts[0].Count.Should().Be(5);
    }

    [Fact]
    public async Task GetSuspicious_FailedLoginBurst_CollectsDistinctIpAddresses()
    {
        var now = DateTime.UtcNow;
        SeedLoginFailed("dave", "1.1.1.1", now.AddMinutes(-1));
        SeedLoginFailed("dave", "1.1.1.1", now.AddMinutes(-2));
        SeedLoginFailed("dave", "2.2.2.2", now.AddMinutes(-3));
        SeedLoginFailed("dave", null, now.AddMinutes(-4)); // null IP must be dropped
        SeedLoginFailed("dave", "2.2.2.2", now.AddMinutes(-5));
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.FailedLoginBursts.Should().HaveCount(1);
        report.FailedLoginBursts[0].IpAddresses.Should().Equal("1.1.1.1", "2.2.2.2");
    }

    [Fact]
    public async Task GetSuspicious_BulkDelete_FlagsAtThreshold()
    {
        var now = DateTime.UtcNow;
        for (var i = 0; i < 5; i++)
            SeedRow(action: AuditActions.Delete, userId: TestUserId, createdAt: now.AddMinutes(-i));
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.BulkDeleteBursts.Should().HaveCount(1);
        var burst = report.BulkDeleteBursts[0];
        burst.UserId.Should().Be(TestUserId);
        burst.UserName.Should().Be("Test User"); // resolved from the seeded TestUser
        burst.Count.Should().Be(5);
    }

    [Fact]
    public async Task GetSuspicious_BulkDelete_RecordsDistinctEntityTypes()
    {
        var now = DateTime.UtcNow;
        SeedRow(entityType: "Sale", action: AuditActions.Delete, userId: TestUserId, createdAt: now.AddMinutes(-1));
        SeedRow(entityType: "Sale", action: AuditActions.Delete, userId: TestUserId, createdAt: now.AddMinutes(-2));
        SeedRow(entityType: "User", action: AuditActions.Delete, userId: TestUserId, createdAt: now.AddMinutes(-3));
        SeedRow(entityType: "User", action: AuditActions.Delete, userId: TestUserId, createdAt: now.AddMinutes(-4));
        SeedRow(entityType: "Customer", action: AuditActions.Delete, userId: TestUserId, createdAt: now.AddMinutes(-5));
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.BulkDeleteBursts.Should().HaveCount(1);
        report.BulkDeleteBursts[0].EntityTypes.Should().Equal("Customer", "Sale", "User"); // sorted distinct
    }

    [Fact]
    public async Task GetSuspicious_ScopedToMarket_IgnoresOtherTenants()
    {
        var now = DateTime.UtcNow;
        var otherMarket = TestMarketId + 1000;

        // 5 failed logins in OUR market — should flag.
        for (var i = 0; i < 5; i++)
            SeedLoginFailed("eve", "1.2.3.4", now.AddMinutes(-i), marketId: TestMarketId);
        // 5 failed logins in ANOTHER market — must be invisible to us.
        for (var i = 0; i < 5; i++)
            SeedLoginFailed("frank", "9.9.9.9", now.AddMinutes(-i), marketId: otherMarket);
        await DbContext.SaveChangesAsync();

        var report = await QueryService().GetSuspiciousAsync(TestMarketId);

        report.FailedLoginBursts.Should().HaveCount(1);
        report.FailedLoginBursts[0].Username.Should().Be("eve");
    }
}
