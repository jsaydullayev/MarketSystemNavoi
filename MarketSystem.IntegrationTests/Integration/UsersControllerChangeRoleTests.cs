using System.Reflection;
using System.Security.Claims;
using MarketSystem.API.Authorization;
using MarketSystem.API.Controllers;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using FluentAssertions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Controller-level contract of <see cref="UsersController.ChangeRole"/>: the
/// endpoint is Owner-only — users.manage is NOT enough, since an Owner may grant
/// it to a Seller who would then promote themselves — and a real role change is
/// journaled as RoleChange with from/to.
/// </summary>
public class UsersControllerChangeRoleTests
{
    private const int CallerMarketId = 42;

    private readonly Mock<IUserService> _userServiceMock = new();
    private readonly Mock<ICurrentMarketService> _currentMarketServiceMock = new();
    private readonly Mock<IAuditLogService> _auditLogServiceMock = new();
    private readonly Guid _targetId = Guid.NewGuid();
    private object? _auditPayload;

    public UsersControllerChangeRoleTests()
    {
        _currentMarketServiceMock.Setup(x => x.TryGetCurrentMarketId()).Returns(CallerMarketId);
        _auditLogServiceMock
            .Setup(x => x.LogActionAsync(
                It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<string>(),
                It.IsAny<Guid>(), It.IsAny<object?>(), It.IsAny<CancellationToken>()))
            .Callback<string, Guid, string, Guid, object?, CancellationToken>(
                (_, _, _, _, payload, _) => _auditPayload = payload)
            .Returns(Task.CompletedTask);
    }

    private UsersController OwnerController()
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.Role, Role.Owner.ToString()),
            new Claim(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()),
        };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
        return new UsersController(
            _userServiceMock.Object,
            _currentMarketServiceMock.Object,
            _auditLogServiceMock.Object)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = principal }
            }
        };
    }

    private UserDto FakeUser(string role) => new(
        _targetId, "Ali Valiyev", "ali", null, role, "uz", true, CallerMarketId,
        "Active", null, null, true, new List<string>());

    private void SetupRoles(string before, string after)
    {
        _userServiceMock
            .Setup(x => x.GetUserByIdAsync(_targetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(FakeUser(before));
        _userServiceMock
            .Setup(x => x.ChangeUserRoleAsync(
                _targetId, It.IsAny<ChangeRoleDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(FakeUser(after));
    }

    [Fact]
    public void ChangeRole_IsOwnerOnly_NotJustUsersManage()
    {
        var action = typeof(UsersController).GetMethod(nameof(UsersController.ChangeRole))!;

        action.GetCustomAttributes<AuthorizeAttribute>(true)
            .Should().ContainSingle(a => a.Policy == "OwnerOnly");
        action.GetCustomAttributes<RequirePermissionAttribute>(true)
            .Should().BeEmpty("users.manage alone must not be enough to hand out roles");
    }

    [Fact]
    public async Task ChangeRole_RealChange_IsJournaledWithFromAndTo()
    {
        SetupRoles(before: "Admin", after: "Seller");

        var result = await OwnerController().ChangeRole(_targetId, new ChangeRoleDto("Seller"));

        result.Result.Should().BeOfType<OkObjectResult>();
        _auditLogServiceMock.Verify(x => x.LogActionAsync(
            AuditEntityTypes.User, _targetId, AuditActions.RoleChange, It.IsAny<Guid>(),
            It.IsAny<object?>(), It.IsAny<CancellationToken>()), Times.Once);
        _auditPayload.Should().BeEquivalentTo(
            new { Username = "ali", fromRole = "Admin", toRole = "Seller" });
    }

    [Fact]
    public async Task ChangeRole_SameRole_WritesNoAudit()
    {
        SetupRoles(before: "Seller", after: "Seller");

        var result = await OwnerController().ChangeRole(_targetId, new ChangeRoleDto("Seller"));

        result.Result.Should().BeOfType<OkObjectResult>();
        _auditLogServiceMock.Verify(x => x.LogActionAsync(
            It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<Guid>(),
            It.IsAny<object?>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task ChangeRole_RejectedByService_Returns400()
    {
        _userServiceMock
            .Setup(x => x.ChangeUserRoleAsync(
                _targetId, It.IsAny<ChangeRoleDto>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Owner rolini o'zgartirib bo'lmaydi."));

        var result = await OwnerController().ChangeRole(_targetId, new ChangeRoleDto("Seller"));

        result.Result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task ChangeRole_UnknownUser_Returns404()
    {
        var result = await OwnerController().ChangeRole(_targetId, new ChangeRoleDto("Admin"));

        result.Result.Should().BeOfType<NotFoundResult>();
    }
}
