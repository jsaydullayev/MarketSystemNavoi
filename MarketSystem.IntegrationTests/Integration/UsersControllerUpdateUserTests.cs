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
/// Controller-level guard of <see cref="UsersController.UpdateUser"/>: Admin
/// accounts are the Owner's to edit. The endpoint sets passwords, so a
/// users.manage holder must not be able to reset a fellow Admin's password and
/// log in as them; Seller accounts stay editable with users.manage.
/// </summary>
public class UsersControllerUpdateUserTests
{
    private const int CallerMarketId = 42;

    private readonly Mock<IUserService> _userServiceMock = new();
    private readonly Mock<ICurrentMarketService> _currentMarketServiceMock = new();
    private readonly Mock<IAuditLogService> _auditLogServiceMock = new();
    private readonly Guid _targetId = Guid.NewGuid();

    public UsersControllerUpdateUserTests()
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

    private UserDto FakeUser(string role) => new(
        _targetId, "Ali Valiyev", "ali", null, role, "uz", true, CallerMarketId,
        "Active", null, null, true, new List<string>());

    private UpdateUserDto PasswordReset() =>
        new(Id: _targetId, FullName: "Ali Valiyev", Password: "NewPassw0rd1", IsActive: true);

    private void SetupTarget(string role)
    {
        _userServiceMock
            .Setup(x => x.GetUserByIdAsync(_targetId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(FakeUser(role));
        _userServiceMock
            .Setup(x => x.UpdateUserAsync(It.IsAny<UpdateUserDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(FakeUser(role));
    }

    [Theory]
    [InlineData(Role.Admin)]
    [InlineData(Role.Seller)]
    public async Task UpdateUser_AdminTargetByNonOwner_ForbidsAndSkipsService(Role callerRole)
    {
        SetupTarget("Admin");

        var result = await ControllerAs(callerRole).UpdateUser(_targetId, PasswordReset());

        result.Result.Should().BeOfType<ForbidResult>(
            "resetting a fellow Admin's password would let the caller log in as them");
        _userServiceMock.Verify(
            x => x.UpdateUserAsync(It.IsAny<UpdateUserDto>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Theory]
    [InlineData(Role.Owner)]
    [InlineData(Role.SuperAdmin)]
    public async Task UpdateUser_AdminTargetByOwnerOrSuperAdmin_Updates(Role callerRole)
    {
        SetupTarget("Admin");

        var result = await ControllerAs(callerRole).UpdateUser(_targetId, PasswordReset());

        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task UpdateUser_SellerTargetByAdmin_StillAllowed()
    {
        SetupTarget("Seller");

        var result = await ControllerAs(Role.Admin).UpdateUser(_targetId, PasswordReset());

        result.Result.Should().BeOfType<OkObjectResult>(
            "users.manage still covers editing Sellers");
    }
}
