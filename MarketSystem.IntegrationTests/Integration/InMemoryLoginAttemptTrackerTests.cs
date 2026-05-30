using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Unit tests for the brute-force tracker (Plan 05 Bosqich 3). No DbContext
/// or DI — the tracker is pure in-memory state, so each test gets a fresh
/// instance. The DB-backed variant is covered separately in
/// <see cref="DbLoginAttemptTrackerTests"/>; this file pins the contract
/// semantics so any future tracker (in-memory, DB, Redis, …) can run the
/// same scenarios.
/// </summary>
public class InMemoryLoginAttemptTrackerTests
{
    private const int Threshold = 5; // mirror the constant inside the impl

    [Fact]
    public void GetLockedUntilUtc_UnknownUsername_ReturnsNull()
    {
        var tracker = new InMemoryLoginAttemptTracker();

        tracker.GetLockedUntilUtc("nobody").Should().BeNull();
    }

    [Fact]
    public async Task RecordFailure_BelowThreshold_DoesNotLock()
    {
        var tracker = new InMemoryLoginAttemptTracker();

        for (var i = 1; i < Threshold; i++)
        {
            var result = await tracker.RecordFailureAsync("bob");
            result.FailureCount.Should().Be(i);
            result.LockedUntilUtc.Should().BeNull();
        }

        tracker.GetLockedUntilUtc("bob").Should().BeNull();
    }

    [Fact]
    public async Task RecordFailure_AtThreshold_LocksAccount()
    {
        var tracker = new InMemoryLoginAttemptTracker();

        LoginFailureResult? last = null;
        for (var i = 0; i < Threshold; i++)
            last = await tracker.RecordFailureAsync("alice");

        last!.FailureCount.Should().Be(Threshold);
        last.LockedUntilUtc.Should().NotBeNull();
        last.LockedUntilUtc.Should().BeAfter(DateTime.UtcNow);

        // Subsequent IsLocked call must agree.
        tracker.GetLockedUntilUtc("alice").Should().NotBeNull();
    }

    [Fact]
    public async Task RecordFailure_AfterLock_DoesNotExtendIt()
    {
        var tracker = new InMemoryLoginAttemptTracker();

        for (var i = 0; i < Threshold; i++)
            await tracker.RecordFailureAsync("carol");
        var firstLockUntil = tracker.GetLockedUntilUtc("carol")!.Value;

        // Hammer the account — would-be attacker keeps trying.
        for (var i = 0; i < 10; i++)
            await tracker.RecordFailureAsync("carol");

        // The lock end time must NOT have advanced. Otherwise an attacker
        // could keep a legitimate user permanently locked out.
        var lockAfterAbuse = tracker.GetLockedUntilUtc("carol")!.Value;
        lockAfterAbuse.Should().Be(firstLockUntil);

        // And the threshold-triggering "just locked" signal is one-shot:
        // re-firing RecordFailure on an already-locked account must NOT
        // resurface LockedUntilUtc (otherwise the caller would re-throw on
        // every attempt, not just the one that tripped the lock).
        var followUp = await tracker.RecordFailureAsync("carol");
        followUp.LockedUntilUtc.Should().BeNull();
    }

    [Fact]
    public async Task RecordSuccess_ClearsFailureHistory()
    {
        var tracker = new InMemoryLoginAttemptTracker();

        // One typo doesn't deserve a slow march toward lockout.
        for (var i = 0; i < Threshold - 1; i++)
            await tracker.RecordFailureAsync("dave");

        await tracker.RecordSuccessAsync("dave");

        // A fresh failure starts from 1, not from Threshold-1 + 1 = Threshold.
        var afterReset = await tracker.RecordFailureAsync("dave");
        afterReset.FailureCount.Should().Be(1);
        afterReset.LockedUntilUtc.Should().BeNull();
    }

    [Fact]
    public async Task GetLockedUntilUtc_UsernameCasing_IsCaseInsensitive()
    {
        // The auth stack stores usernames lowercase — the tracker key must
        // collapse the same way so "Bob"/"bob" can't bypass the lock.
        var tracker = new InMemoryLoginAttemptTracker();
        for (var i = 0; i < Threshold; i++)
            await tracker.RecordFailureAsync("MixedCase");

        tracker.GetLockedUntilUtc("mixedcase").Should().NotBeNull();
        tracker.GetLockedUntilUtc("MIXEDCASE").Should().NotBeNull();
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public async Task RecordFailure_EmptyUsername_IsNoOp(string? username)
    {
        var tracker = new InMemoryLoginAttemptTracker();

        var result = await tracker.RecordFailureAsync(username!);

        result.FailureCount.Should().Be(0);
        result.LockedUntilUtc.Should().BeNull();
    }

    [Fact]
    public async Task OneUsernameLocked_DoesNotAffectAnother()
    {
        var tracker = new InMemoryLoginAttemptTracker();

        for (var i = 0; i < Threshold; i++)
            await tracker.RecordFailureAsync("victim");

        tracker.GetLockedUntilUtc("victim").Should().NotBeNull();
        tracker.GetLockedUntilUtc("bystander").Should().BeNull();
    }
}
