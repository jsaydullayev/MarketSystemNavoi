using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Verifies the hybrid <see cref="DbRevokedTokenStore"/> — its hot-path
/// <see cref="DbRevokedTokenStore.IsRevoked"/> reads stay in memory, but
/// <see cref="DbRevokedTokenStore.RevokeAsync"/> writes also hit the
/// RevokedTokens table so revocations survive a process restart, and
/// <see cref="DbRevokedTokenStore.LoadFromDbAsync"/> rehydrates the cache
/// the next time the app boots.
/// </summary>
public class DbRevokedTokenStoreTests : TestBase
{
    private DbRevokedTokenStore CreateStore()
    {
        var scopeFactory = ServiceProvider.GetRequiredService<IServiceScopeFactory>();
        return new DbRevokedTokenStore(
            scopeFactory,
            NullLogger<DbRevokedTokenStore>.Instance);
    }

    [Fact]
    public async Task RevokeAsync_PersistsToDbAndCachesInMemory()
    {
        var store = CreateStore();
        var jti = Guid.NewGuid().ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(30);

        await store.RevokeAsync(jti, expiresAt);

        // Memory cache — IsRevoked must answer without a DB hit.
        store.IsRevoked(jti).Should().BeTrue();

        // DB persistence — the row is what lets a different replica / a
        // restart see the revocation.
        ClearDbContext();
        var row = await DbContext.RevokedTokens.SingleAsync(r => r.Jti == jti);
        row.ExpiresAtUtc.Should().BeCloseTo(expiresAt, TimeSpan.FromSeconds(5));
        row.RevokedAtUtc.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
    }

    [Fact]
    public void IsRevoked_UnknownJti_ReturnsFalse()
    {
        var store = CreateStore();
        store.IsRevoked("does-not-exist").Should().BeFalse();
    }

    [Fact]
    public async Task IsRevoked_ExpiredEntry_IsTreatedAsNotRevoked()
    {
        var store = CreateStore();
        var jti = "already-expired";
        // ExpiresAtUtc in the past — the entry is harmless and IsRevoked
        // must return false so a fresh token isn't blocked by garbage.
        await store.RevokeAsync(jti, DateTime.UtcNow.AddSeconds(-1));

        store.IsRevoked(jti).Should().BeFalse();
    }

    [Fact]
    public async Task LoadFromDbAsync_HydratesActiveAndPrunesExpired()
    {
        // Seed the DB directly to simulate "the table already has entries
        // from before this process started".
        var liveJti = "live-token";
        var deadJti = "dead-token";
        DbContext.RevokedTokens.AddRange(
            new RevokedToken
            {
                Jti = liveJti,
                ExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
                RevokedAtUtc = DateTime.UtcNow.AddMinutes(-1),
            },
            new RevokedToken
            {
                Jti = deadJti,
                ExpiresAtUtc = DateTime.UtcNow.AddMinutes(-30),
                RevokedAtUtc = DateTime.UtcNow.AddHours(-2),
            });
        await DbContext.SaveChangesAsync();
        ClearDbContext();

        var store = CreateStore();
        await store.LoadFromDbAsync();

        // Live entry — still blocking.
        store.IsRevoked(liveJti).Should().BeTrue();
        // Dead entry — must be invisible to the cache AND scrubbed from the DB
        // so the table never grows unbounded.
        store.IsRevoked(deadJti).Should().BeFalse();

        ClearDbContext();
        var remaining = await DbContext.RevokedTokens.ToListAsync();
        remaining.Should().ContainSingle()
            .Which.Jti.Should().Be(liveJti);
    }

    [Fact]
    public async Task RevokeAsync_SameJtiTwice_DoesNotDuplicate()
    {
        var store = CreateStore();
        var jti = "idempotent-jti";
        var expiresAt = DateTime.UtcNow.AddMinutes(30);

        await store.RevokeAsync(jti, expiresAt);
        await store.RevokeAsync(jti, expiresAt);

        ClearDbContext();
        var count = await DbContext.RevokedTokens.CountAsync(r => r.Jti == jti);
        count.Should().Be(1);
    }

    [Fact]
    public async Task RevokeAsync_EmptyJti_IsNoOp()
    {
        var store = CreateStore();

        await store.RevokeAsync(string.Empty, DateTime.UtcNow.AddMinutes(30));

        store.IsRevoked(string.Empty).Should().BeFalse();
        ClearDbContext();
        (await DbContext.RevokedTokens.CountAsync()).Should().Be(0);
    }
}
