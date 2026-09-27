using MarketSystem.Application.DTOs;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// <see cref="UserService.ChangeUserRoleAsync"/> — the Owner moving an employee
/// between Admin and Seller. The contract that matters: role-scoped state
/// (explicit permissions, work shift) resets together with the role, so a
/// demotion really takes privileges away, and the moved user's sessions die.
/// </summary>
public class UserServiceChangeRoleTests : TestBase
{
    private readonly FakeUserTokenEpochStore _epochStore = new();

    private UserService CreateService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new UserService(unitOfWork, DbContext, CurrentMarketServiceMock.Object, _epochStore);
    }

    private async Task<User> SeedUserAsync(Role role, int? marketId = null, Action<User>? configure = null)
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = $"{role} user",
            Username = $"{role.ToString().ToLowerInvariant()}_{Guid.NewGuid():N}",
            PasswordHash = "x",
            Role = role,
            Language = Language.Uzbek,
            IsActive = true,
            MarketId = marketId ?? TestMarketId,
        };
        configure?.Invoke(user);
        DbContext.Users.Add(user);
        await DbContext.SaveChangesAsync();
        ClearDbContext();
        return user;
    }

    private async Task<User> ReloadAsync(Guid id)
    {
        ClearDbContext();
        return await DbContext.Users.FirstAsync(u => u.Id == id);
    }

    [Fact]
    public async Task Demoting_CustomizedAdmin_DropsTheAdminPermissions()
    {
        // The Owner switched off a single Admin permission, so the user is
        // "customised" and carries an explicit, Admin-sized permission list.
        var admin = await SeedUserAsync(Role.Admin, configure: u =>
        {
            u.Permissions = PermissionDefaults.Admin
                .Where(k => k != PermissionKeys.ProductsDelete).ToList();
            u.IsPermissionsCustomized = true;
        });

        var dto = await CreateService().ChangeUserRoleAsync(admin.Id, new ChangeRoleDto("Seller"));

        dto!.Role.Should().Be("Seller");
        var saved = await ReloadAsync(admin.Id);
        saved.Role.Should().Be(Role.Seller);
        saved.IsPermissionsCustomized.Should().BeFalse();
        saved.Permissions.Should().BeEmpty();
        saved.GetEffectivePermissions().Should().BeEquivalentTo(PermissionDefaults.Seller);
        saved.GetEffectivePermissions().Should().NotContain(PermissionKeys.UsersManage,
            "a demoted Admin must not keep users.manage and promote themselves back");
    }

    [Fact]
    public async Task Promoting_CustomizedSeller_GetsTheAdminDefaults()
    {
        var seller = await SeedUserAsync(Role.Seller, configure: u =>
        {
            u.Permissions = PermissionDefaults.Seller
                .Append(PermissionKeys.NotificationsAccess).ToList();
            u.IsPermissionsCustomized = true;
        });

        await CreateService().ChangeUserRoleAsync(seller.Id, new ChangeRoleDto("admin"));

        var saved = await ReloadAsync(seller.Id);
        saved.Role.Should().Be(Role.Admin);
        saved.GetEffectivePermissions().Should().BeEquivalentTo(PermissionDefaults.Admin);
    }

    [Fact]
    public async Task RoleChange_KillsEverySessionOfTheUser()
    {
        var seller = await SeedUserAsync(Role.Seller);
        DbContext.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = seller.Id,
            Token = "live-refresh-token",
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            SessionStartedAt = DateTime.UtcNow,
        });
        await DbContext.SaveChangesAsync();
        ClearDbContext();

        await CreateService().ChangeUserRoleAsync(seller.Id, new ChangeRoleDto("Admin"));

        var saved = await ReloadAsync(seller.Id);
        saved.TokensInvalidBeforeUtc.Should().NotBeNull(
            "issued access tokens carry the old role and permissions");
        _epochStore.Stamped.Should().ContainKey(seller.Id);
        (await DbContext.RefreshTokens.SingleAsync(r => r.UserId == seller.Id))
            .IsRevoked.Should().BeTrue();
    }

    [Fact]
    public async Task Demoting_AdminWithLeftoverShiftBlock_CanStillWork()
    {
        // Blocked during an earlier Seller stint, then promoted: Admins are not
        // shift-gated, so the block sat unseen. Demotion must not resurrect it.
        var admin = await SeedUserAsync(Role.Admin, configure: u => u.ShiftStatus = ShiftStatus.Blocked);

        await CreateService().ChangeUserRoleAsync(admin.Id, new ChangeRoleDto("Seller"));

        var saved = await ReloadAsync(admin.Id);
        saved.ShiftStatus.Should().Be(ShiftStatus.Active);
        saved.IsShiftActiveNow().Should().BeTrue();
    }

    [Fact]
    public async Task SameRole_IsANoOp_KeepsSessionsAndCustomPermissions()
    {
        var custom = new List<string> { PermissionKeys.SalesAccess, PermissionKeys.SalesCreate };
        var seller = await SeedUserAsync(Role.Seller, configure: u =>
        {
            u.Permissions = custom;
            u.IsPermissionsCustomized = true;
        });

        var dto = await CreateService().ChangeUserRoleAsync(seller.Id, new ChangeRoleDto("Seller"));

        dto!.Role.Should().Be("Seller");
        var saved = await ReloadAsync(seller.Id);
        saved.TokensInvalidBeforeUtc.Should().BeNull("nobody should be logged out for a no-op");
        _epochStore.Stamped.Should().NotContainKey(seller.Id);
        saved.IsPermissionsCustomized.Should().BeTrue();
        saved.Permissions.Should().BeEquivalentTo(custom);
    }

    [Theory]
    [InlineData(Role.Owner)]
    [InlineData(Role.SuperAdmin)]
    public async Task OwnerOrSuperAdminTarget_IsRejected(Role targetRole)
    {
        var target = await SeedUserAsync(targetRole);

        var act = () => CreateService().ChangeUserRoleAsync(target.Id, new ChangeRoleDto("Seller"));

        await act.Should().ThrowAsync<InvalidOperationException>();
        (await ReloadAsync(target.Id)).Role.Should().Be(targetRole);
    }

    [Theory]
    [InlineData("Owner")]
    [InlineData("SuperAdmin")]
    [InlineData("Manager")]
    public async Task OnlyAdminOrSeller_CanBeAssigned(string requestedRole)
    {
        var seller = await SeedUserAsync(Role.Seller);

        var act = () => CreateService().ChangeUserRoleAsync(seller.Id, new ChangeRoleDto(requestedRole));

        await act.Should().ThrowAsync<InvalidOperationException>();
        (await ReloadAsync(seller.Id)).Role.Should().Be(Role.Seller);
    }

    [Fact]
    public async Task UserOfAnotherMarket_IsNotFound()
    {
        var foreign = await SeedUserAsync(Role.Seller, marketId: TestMarketId + 10_000);

        var dto = await CreateService().ChangeUserRoleAsync(foreign.Id, new ChangeRoleDto("Admin"));

        dto.Should().BeNull();
        (await ReloadAsync(foreign.Id)).Role.Should().Be(Role.Seller);
    }
}
