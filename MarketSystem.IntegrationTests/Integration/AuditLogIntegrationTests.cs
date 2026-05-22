using System.Net;
using MarketSystem.Application.Services;
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
            httpContextAccessor);
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
}
