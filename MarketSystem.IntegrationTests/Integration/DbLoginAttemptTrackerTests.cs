using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Verifies the hybrid <see cref="DbLoginAttemptTracker"/> — its hot-path
/// <c>GetLockedUntilUtc</c> reads stay in memory, but
/// <c>RecordFailureAsync</c> / <c>RecordSuccessAsync</c> writes also hit the
/// LoginAttempts table so the lockout survives a process restart, and
/// <c>LoadFromDbAsync</c> rehydrates the cache the next time the app boots.
///
/// The M1 hardening is the whole point of this class — pure in-memory state
/// was bypassable by anything that triggered an API restart, so these tests
/// pin the "restart survives" property.
/// </summary>
public class DbLoginAttemptTrackerTests : TestBase
{
    private const int Threshold = 5; // mirror the constant inside the impl

    private DbLoginAttemptTracker CreateTracker()
    {
        var scopeFactory = ServiceProvider.GetRequiredService<IServiceScopeFactory>();
        return new DbLoginAttemptTracker(
            scopeFactory,
            NullLogger<DbLoginAttemptTracker>.Instance);
    }

    [Fact]
    public async Task RecordFailureAsync_PersistsToDbAndCachesInMemory()
    {
        var tracker = CreateTracker();

        var result = await tracker.RecordFailureAsync("bob");
        result.FailureCount.Should().Be(1);
        result.LockedUntilUtc.Should().BeNull();

        // Memory cache — GetLockedUntilUtc must answer without a DB hit.
        tracker.GetLockedUntilUtc("bob").Should().BeNull();

        // DB persistence — the row is what lets a restart see the counter.
        ClearDbContext();
        var row = await DbContext.LoginAttempts.SingleAsync(a => a.Username == "bob");
        row.FailureCount.Should().Be(1);
        row.LockedUntilUtc.Should().BeNull();
    }

    [Fact]
    public async Task RecordFailureAsync_AtThreshold_LocksAndPersistsLock()
    {
        var tracker = CreateTracker();

        LoginFailureResult? last = null;
        for (var i = 0; i < Threshold; i++)
            last = await tracker.RecordFailureAsync("alice");

        last!.FailureCount.Should().Be(Threshold);
        last.LockedUntilUtc.Should().NotBeNull();
        tracker.GetLockedUntilUtc("alice").Should().NotBeNull();

        ClearDbContext();
        var row = await DbContext.LoginAttempts.SingleAsync(a => a.Username == "alice");
        row.FailureCount.Should().Be(Threshold);
        row.LockedUntilUtc.Should().NotBeNull();
    }

    [Fact]
    public async Task RecordSuccessAsync_RemovesFromCacheAndDb()
    {
        var tracker = CreateTracker();
        for (var i = 0; i < Threshold - 1; i++)
            await tracker.RecordFailureAsync("dave");

        await tracker.RecordSuccessAsync("dave");

        tracker.GetLockedUntilUtc("dave").Should().BeNull();

        ClearDbContext();
        (await DbContext.LoginAttempts.AnyAsync(a => a.Username == "dave"))
            .Should().BeFalse();

        // And a fresh failure starts from 1 (the row was actually wiped,
        // not just the lock cleared).
        var afterReset = await tracker.RecordFailureAsync("dave");
        afterReset.FailureCount.Should().Be(1);
    }

    [Fact]
    public async Task LoadFromDbAsync_RehydratesActiveLock()
    {
        // M1 — the core scenario. Seed the table with a row that represents
        // "this username was locked on the previous process; this new
        // process must see them as still locked".
        var lockedUntil = DateTime.UtcNow.AddMinutes(10);
        DbContext.LoginAttempts.Add(new LoginAttempt
        {
            Username = "previously-locked",
            FailureCount = Threshold,
            FirstFailureUtc = DateTime.UtcNow.AddMinutes(-2),
            LockedUntilUtc = lockedUntil,
            UpdatedAtUtc = DateTime.UtcNow,
        });
        await DbContext.SaveChangesAsync();
        ClearDbContext();

        var tracker = CreateTracker();
        await tracker.LoadFromDbAsync();

        var fromCache = tracker.GetLockedUntilUtc("previously-locked");
        fromCache.Should().NotBeNull();
        fromCache!.Value.Should().BeCloseTo(lockedUntil, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public async Task LoadFromDbAsync_PrunesFullyStaleRows()
    {
        // A row whose window AND lock have both expired is forensic noise —
        // the startup sweep should reclaim the space so the table stays
        // bounded over time.
        DbContext.LoginAttempts.Add(new LoginAttempt
        {
            Username = "long-gone",
            FailureCount = Threshold,
            FirstFailureUtc = DateTime.UtcNow.AddHours(-2),
            LockedUntilUtc = DateTime.UtcNow.AddHours(-1),
            UpdatedAtUtc = DateTime.UtcNow.AddHours(-1),
        });
        await DbContext.SaveChangesAsync();
        ClearDbContext();

        var tracker = CreateTracker();
        await tracker.LoadFromDbAsync();

        tracker.GetLockedUntilUtc("long-gone").Should().BeNull();

        ClearDbContext();
        (await DbContext.LoginAttempts.AnyAsync(a => a.Username == "long-gone"))
            .Should().BeFalse();
    }

    [Fact]
    public async Task RecordFailureAsync_UsernameCasing_IsCaseInsensitive()
    {
        var tracker = CreateTracker();
        for (var i = 0; i < Threshold; i++)
            await tracker.RecordFailureAsync("MixedCase");

        tracker.GetLockedUntilUtc("mixedcase").Should().NotBeNull();
        tracker.GetLockedUntilUtc("MIXEDCASE").Should().NotBeNull();

        ClearDbContext();
        // Persisted under the normalized lowercase key, not the original casing.
        (await DbContext.LoginAttempts.AnyAsync(a => a.Username == "mixedcase"))
            .Should().BeTrue();
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public async Task RecordFailureAsync_EmptyUsername_IsNoOp(string? username)
    {
        var tracker = CreateTracker();

        var result = await tracker.RecordFailureAsync(username!);

        result.FailureCount.Should().Be(0);
        result.LockedUntilUtc.Should().BeNull();
        ClearDbContext();
        (await DbContext.LoginAttempts.CountAsync()).Should().Be(0);
    }
}
