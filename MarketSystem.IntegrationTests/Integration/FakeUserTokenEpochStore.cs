using System.Collections.Concurrent;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// In-memory <see cref="IUserTokenEpochStore"/> for tests.
///
/// Mirrors the production store's semantics (cache-only publish, never moves the epoch
/// backwards) and exposes the raw map so tests can assert that a credential change
/// actually stamped the user — the epoch is what kills already-issued access tokens.
/// </summary>
public sealed class FakeUserTokenEpochStore : IUserTokenEpochStore
{
    private readonly ConcurrentDictionary<Guid, DateTime> _cache = new();

    public IReadOnlyDictionary<Guid, DateTime> Stamped => _cache;

    public DateTime? GetEpoch(Guid userId)
        => _cache.TryGetValue(userId, out var epoch) ? epoch : null;

    public void Publish(Guid userId, DateTime utcNow)
    {
        if (userId == Guid.Empty) return;
        _cache.AddOrUpdate(userId, utcNow, (_, existing) => existing > utcNow ? existing : utcNow);
    }

    public Task LoadFromDbAsync(CancellationToken ct = default) => Task.CompletedTask;
}
