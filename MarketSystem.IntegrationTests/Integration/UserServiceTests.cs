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
/// Focused tests for <see cref="UserService"/>. Today's coverage is the
/// soft-delete behaviour added in Plan 07 Bosqich 5 — DeleteUserAsync no
/// longer hard-deletes the row, which would otherwise either fail (FK
/// RESTRICT against AuditLogs.UserId) or rewrite audit history.
/// </summary>
public class UserServiceTests : TestBase
{
    /// Epoch store — testlar undan foydalanuvchi "stamplanganini" tekshirishi mumkin.
    private readonly FakeUserTokenEpochStore _epochStore = new();

    private UserService CreateService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new UserService(unitOfWork, DbContext, CurrentMarketServiceMock.Object, _epochStore);
    }

    [Fact]
    public async Task DeleteUserAsync_SoftDeletes_PreservesRowButHidesFromQueries()
    {
        // Arrange — a regular Admin in the test market we'll "delete".
        var admin = new User
        {
            Id = Guid.NewGuid(),
            FullName = "Admin to remove",
            Username = "admin_to_remove",
            PasswordHash = "x",
            Role = Role.Admin,
            Language = Language.Uzbek,
            IsActive = true,
            MarketId = TestMarketId,
        };
        DbContext.Users.Add(admin);
        await DbContext.SaveChangesAsync();
        ClearDbContext();

        // Act
        var ok = await CreateService().DeleteUserAsync(admin.Id);

        // Assert
        ok.Should().BeTrue();
        ClearDbContext();

        // Hidden from normal lookups by the global IsDeleted query filter…
        var visible = await DbContext.Users.FirstOrDefaultAsync(u => u.Id == admin.Id);
        visible.Should().BeNull("the IsDeleted query filter must hide soft-deleted users");

        // …but the row still exists, so any audit row pointing at it keeps its
        // FK valid. IsActive is cleared too — the user can no longer log in.
        var persisted = await DbContext.Users
            .IgnoreQueryFilters()
            .FirstAsync(u => u.Id == admin.Id);
        persisted.IsDeleted.Should().BeTrue();
        persisted.IsActive.Should().BeFalse();
    }
}
