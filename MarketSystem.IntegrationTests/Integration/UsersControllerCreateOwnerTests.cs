using System.Security.Claims;
using MarketSystem.API.Controllers;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using FluentAssertions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Controller-level tests for the "Owner can add an Owner" capability and its
/// escalation guard in <see cref="UsersController.CreateUser"/>.
///
/// The security contract: creating an Owner is restricted to Owner/SuperAdmin
/// callers. An Admin holding <c>users.manage</c> (enough to create Admin/Seller)
/// must NOT be able to POST <c>role=Owner</c> and self-escalate — the exact
/// Admin→Owner escalation the codebase guards against. Client-side role hiding
/// is cosmetic; this gate is the real boundary.
/// </summary>
public class UsersControllerCreateOwnerTests
{
    private const int CallerMarketId = 42;

    private readonly Mock<IUserService> _userServiceMock = new();
    private readonly Mock<ICurrentMarketService> _currentMarketServiceMock = new();
    private readonly Mock<IAuditLogService> _auditLogServiceMock = new();

    public UsersControllerCreateOwnerTests()
    {
        _currentMarketServiceMock.Setup(x => x.TryGetCurrentMarketId()).Returns(CallerMarketId);
        _auditLogServiceMock
            .Setup(x => x.LogActionAsync(
                It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<string>(),
                It.IsAny<Guid>(), It.IsAny<object?>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
    }

    private UsersController ControllerAs(Role role)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.Role, role.ToString()),
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

    private static CreateUserDto NewUserRequest(string role) =>
        new(FullName: "New Person", Username: "newperson", Password: "Passw0rd1", Role: role);

    private static UserDto FakeUser(string role) => new(
        Guid.NewGuid(), "New Person", "newperson", null, role, "uz", true, CallerMarketId,
        "Active", null, null, false, new List<string>());

    [Theory]
    [InlineData(Role.Admin)]
    [InlineData(Role.Seller)]
    public async Task CreateUser_OwnerRoleRequestedByNonOwner_ForbidsAndSkipsService(Role callerRole)
    {
        var controller = ControllerAs(callerRole);

        var result = await controller.CreateUser(NewUserRequest("Owner"));

        result.Result.Should().BeOfType<ForbidResult>(
            "an Admin/Seller must never be able to create an Owner");
        _userServiceMock.Verify(
            x => x.CreateUserAsync(It.IsAny<CreateUserDto>(), It.IsAny<CancellationToken>()),
            Times.Never,
            "the escalation guard must reject before the service is ever called");
    }

    [Theory]
    [InlineData(Role.Owner)]
    [InlineData(Role.SuperAdmin)]
    public async Task CreateUser_OwnerRoleRequestedByOwnerOrSuperAdmin_CreatesOwner(Role callerRole)
    {
        _userServiceMock
            .Setup(x => x.CreateUserAsync(It.IsAny<CreateUserDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(FakeUser("Owner"));
        var controller = ControllerAs(callerRole);

        var result = await controller.CreateUser(NewUserRequest("Owner"));

        result.Result.Should().BeOfType<CreatedAtActionResult>(
            "an Owner (or SuperAdmin) is allowed to add a co-Owner");
        _userServiceMock.Verify(
            x => x.CreateUserAsync(
                It.Is<CreateUserDto>(d => d.Role == "Owner"), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task CreateUser_AdminRoleRequestedByAdmin_StillAllowed()
    {
        _userServiceMock
            .Setup(x => x.CreateUserAsync(It.IsAny<CreateUserDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(FakeUser("Admin"));
        var controller = ControllerAs(Role.Admin);

        var result = await controller.CreateUser(NewUserRequest("Admin"));

        result.Result.Should().BeOfType<CreatedAtActionResult>(
            "the Owner gate must not block an Admin from creating an Admin/Seller");
        _userServiceMock.Verify(
            x => x.CreateUserAsync(It.IsAny<CreateUserDto>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
