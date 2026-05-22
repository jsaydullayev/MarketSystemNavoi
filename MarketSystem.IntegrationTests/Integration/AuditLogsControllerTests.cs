using System.Security.Claims;
using MarketSystem.API.Controllers;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Enums;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Controller-level tests for <see cref="AuditLogsController"/>. The real
/// security-critical piece is tenant scoping — every non-SuperAdmin caller
/// must be pinned to their own market regardless of the <c>marketId</c>
/// query param. These tests guard that contract by inspecting the filter
/// handed to the (mocked) query service.
/// </summary>
public class AuditLogsControllerTests
{
    private const int CallerMarketId = 42;

    private readonly Mock<IAuditLogQueryService> _queryServiceMock = new();
    private readonly Mock<ICurrentMarketService> _currentMarketServiceMock = new();

    public AuditLogsControllerTests()
    {
        _currentMarketServiceMock
            .Setup(x => x.TryGetCurrentMarketId())
            .Returns(CallerMarketId);
        _queryServiceMock
            .Setup(x => x.QueryAsync(It.IsAny<AuditLogFilter>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PagedResult<AuditLogDto>.Empty(1, 50));
    }

    private AuditLogsController ControllerAs(Role role)
    {
        var claims = new[] { new Claim(ClaimTypes.Role, role.ToString()) };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
        return new AuditLogsController(
            _queryServiceMock.Object,
            _currentMarketServiceMock.Object)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = principal }
            }
        };
    }

    [Theory]
    [InlineData(Role.Owner)]
    [InlineData(Role.Admin)]
    [InlineData(Role.Seller)]
    public async Task Query_NonSuperAdmin_IsPinnedToOwnMarket_IgnoringQueryParam(Role role)
    {
        var controller = ControllerAs(role);

        // The caller tries to peek at marketId=999; the controller must
        // overwrite that with the caller's own market id.
        await controller.Query(
            entityType: null, action: null, userId: null,
            marketId: 999,
            from: null, to: null);

        _queryServiceMock.Verify(x => x.QueryAsync(
            It.Is<AuditLogFilter>(f => f.MarketId == CallerMarketId),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Query_SuperAdmin_HonoursMarketIdQueryParam()
    {
        var controller = ControllerAs(Role.SuperAdmin);

        await controller.Query(
            entityType: null, action: null, userId: null,
            marketId: 99,
            from: null, to: null);

        _queryServiceMock.Verify(x => x.QueryAsync(
            It.Is<AuditLogFilter>(f => f.MarketId == 99),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Query_SuperAdmin_WithoutMarketId_QueriesAllMarkets()
    {
        var controller = ControllerAs(Role.SuperAdmin);

        await controller.Query(
            entityType: null, action: null, userId: null,
            marketId: null,
            from: null, to: null);

        _queryServiceMock.Verify(x => x.QueryAsync(
            It.Is<AuditLogFilter>(f => f.MarketId == null),
            It.IsAny<CancellationToken>()), Times.Once);
    }
}
